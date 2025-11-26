class Activity < ApplicationRecord
  ACTIVITY_TYPES = [ "Call", "Meeting", "Lunch", "Coffee", "Demo", "Presentation" ]
  PRIORITY_LEVELS = [ "Low", "Medium", "High" ]

  belongs_to :contact
  belongs_to :user, optional: true

  validates_presence_of :activity_type, :title
  validates :activity_type, inclusion: { in: ACTIVITY_TYPES }
  validates :priority, inclusion: { in: %w[Low Medium High], allow_blank: true }

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :overdue, -> { pending.where("due_date < ?", DateTime.current) }
  scope :upcoming, -> { pending.where("due_date >= ?", DateTime.current) }
  scope :recent, -> { order(created_at: :desc) }

  def completed?
    completed_at.present?
  end

  def overdue?
    !completed? && due_date.present? && due_date < DateTime.current
  end

  def status
    return "Completed" if completed?
    return "Overdue" if overdue?
    "Scheduled"
  end

  def status_color
    case status
    when "Completed" then "green"
    when "Overdue" then "red"
    else "blue"
    end
  end
end
