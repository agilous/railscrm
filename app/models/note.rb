class Note < ApplicationRecord
  # Multiple associations through join table
  has_many :note_associations, dependent: :destroy
  has_many :contacts, through: :note_associations, source: :notable, source_type: "Contact"
  has_many :leads, through: :note_associations, source: :notable, source_type: "Lead"
  has_many :opportunities, through: :note_associations, source: :notable, source_type: "Opportunity"
  has_many :accounts, through: :note_associations, source: :notable, source_type: "Account"

  belongs_to :user, optional: true

  validates_presence_of :content

  # Helper method to add associations
  # Returns true if a new association was created, false if it already existed
  def add_notable(notable)
    association = note_associations.find_or_create_by(notable: notable)
    association.persisted? && association.created_at == association.updated_at
  end

  # Helper to get all associated notables
  # Optimized to avoid loading all records into memory
  def all_notables
    note_associations.pluck(:notable_type, :notable_id)
      .map { |type, id| type.constantize.find(id) }
  end
end
