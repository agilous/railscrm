class Contact < ApplicationRecord
  # Associations - Only include objects that can be synced from Pipedrive
  has_many :note_associations, as: :notable, dependent: :destroy
  has_many :notes, through: :note_associations
  has_many :activities, dependent: :destroy
  has_many :deals, class_name: "Opportunity", foreign_key: :contact_name, primary_key: :email

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
