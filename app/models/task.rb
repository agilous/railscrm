class Task < ApplicationRecord
  belongs_to :assignee, class_name: "User"

  validates_presence_of :title

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
end
