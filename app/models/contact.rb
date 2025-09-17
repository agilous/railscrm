class Contact < ApplicationRecord
  validates :email, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP,
                             message: "Invalid e-mail address" }
  validates_presence_of :first_name, :last_name, :email

  # Filtering scopes
  scope :by_name, ->(name) { where("first_name ILIKE :name OR last_name ILIKE :name", name: "%#{sanitize_sql_like(name)}%") }
  scope :by_company, ->(company) { where("company ILIKE :company", company: "%#{sanitize_sql_like(company)}%") }
  scope :by_email, ->(email) { where("email ILIKE :email", email: "%#{sanitize_sql_like(email)}%") }
  scope :created_since, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }

  def full_name
    return first_name if last_name.blank?
    "#{first_name} #{last_name}"
  end
end
