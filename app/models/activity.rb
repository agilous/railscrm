class Activity < ApplicationRecord
  belongs_to :contact

  validates_presence_of :activity_type, :title

  ACTIVITY_TYPES = [ "Call", "Meeting", "Lunch", "Coffee", "Demo", "Presentation" ]

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :overdue, -> { pending.where("due_date < ?", DateTime.current) }
  scope :upcoming, -> { pending.where("due_date >= ?", DateTime.current) }
  scope :recent, -> { order(created_at: :desc) }
end
