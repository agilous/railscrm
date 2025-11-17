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
        # Check if any notes have multiple associations
        multi_association_count = execute(<<-SQL).first['count'].to_i
          SELECT COUNT(DISTINCT note_id) as count
          FROM (
            SELECT note_id, COUNT(*) as association_count
            FROM note_associations
            GROUP BY note_id
            HAVING COUNT(*) > 1
          ) multi_notes
        SQL

        if multi_association_count > 0
          puts "\n" + "="*70
          puts "WARNING: DATA LOSS RISK"
          puts "="*70
          puts "#{multi_association_count} notes have multiple associations that will be lost!"
          puts "Only the oldest association for each note will be preserved."
          puts "\nDo you want to continue with the rollback? (y/N)"
          puts "Auto-continuing in 15 seconds..."

          begin
            require 'timeout'
            response = Timeout.timeout(15) do
              STDIN.gets&.chomp&.downcase
            end
          rescue Timeout::Error
            response = 'y' # Auto-proceed for scripted environments
            puts "No response received, proceeding with rollback..."
          end

          if response != 'y'
            puts "Rollback cancelled. Please backup note_associations table first."
            raise ActiveRecord::IrreversibleMigration,
              "Rollback halted to prevent data loss. Backup note_associations before proceeding."
          end
        end

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
