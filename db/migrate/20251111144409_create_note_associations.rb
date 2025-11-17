class CreateNoteAssociations < ActiveRecord::Migration[8.0]
  def change
    create_table :note_associations do |t|
      t.references :note, null: false, foreign_key: true
      t.references :notable, polymorphic: true, null: false

      t.timestamps
    end

    # Add index for uniqueness - a note can only be associated once with each notable
    add_index :note_associations, [ :note_id, :notable_type, :notable_id ],
              unique: true,
              name: 'index_unique_note_associations'

    # Migrate existing notes data to the new structure
    reversible do |direction|
      direction.up do
        # Copy existing associations to the new table
        execute <<-SQL
          INSERT INTO note_associations (note_id, notable_type, notable_id, created_at, updated_at)
          SELECT id, notable_type, notable_id, created_at, updated_at
          FROM notes
          WHERE notable_type IS NOT NULL AND notable_id IS NOT NULL
        SQL

        # Remove the old columns from notes table
        remove_reference :notes, :notable, polymorphic: true
      end

      direction.down do
        # Re-add the polymorphic columns
        add_reference :notes, :notable, polymorphic: true

        # Copy the first association back (we'll lose multiple associations)
        execute <<-SQL
          UPDATE notes
          SET notable_type = na.notable_type,
              notable_id = na.notable_id
          FROM (
            SELECT DISTINCT ON (note_id) note_id, notable_type, notable_id
            FROM note_associations
            ORDER BY note_id, created_at ASC
          ) na
          WHERE notes.id = na.note_id
        SQL
      end
    end
  end
end
