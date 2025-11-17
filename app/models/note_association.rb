class NoteAssociation < ApplicationRecord
  belongs_to :note
  belongs_to :notable, polymorphic: true

  validates :note_id, uniqueness: { scope: [ :notable_type, :notable_id ] }
end
