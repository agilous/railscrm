class Task < ApplicationRecord
  belongs_to :assignee, class_name: "User"

  validates_presence_of :title

  # Filtering scopes
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :by_title, ->(title) { where("title ILIKE :title", title: "%#{sanitize_sql_like(title)}%") }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_assignee, ->(assignee_id) { where(assignee_id: assignee_id) }
  scope :created_since, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }
  scope :due_after, ->(date) { where("due_date >= ?", date) }
  scope :due_before, ->(date) { where("due_date <= ?", date) }
end
