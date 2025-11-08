class Account < ApplicationRecord
  validates_presence_of :name, :phone
  validates :name, uniqueness: true

  # Filtering scopes
  scope :by_name, ->(name) { where("name ILIKE :name", name: "%#{sanitize_sql_like(name)}%") }
  scope :by_email, ->(email) { where("email ILIKE :email", email: "%#{sanitize_sql_like(email)}%") }
  scope :by_assigned_to, ->(assigned_to) { where("assigned_to ILIKE :assigned_to", assigned_to: "%#{sanitize_sql_like(assigned_to)}%") }
  scope :created_since, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }
end
