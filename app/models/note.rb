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
    association.previously_new_record?
  end

  # Helper to get all associated notables as relations (not loaded records)
  def all_notables
    contacts + leads + opportunities + accounts
  end
end
