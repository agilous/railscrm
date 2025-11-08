class Lead < ApplicationRecord
  # In Rails 8 with ActiveRecord, we'll use composition over inheritance
  # Include contact fields directly instead of inheriting from Contact

  belongs_to :assigned_to, class_name: "User"
  has_many :notes, as: :notable
  accepts_nested_attributes_for :notes, allow_destroy: true

  validates_presence_of :lead_owner
  validates :email, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP,
                             message: "Invalid e-mail address" }
  validates_presence_of :first_name, :last_name, :email

  STATUS = [ [ "New", "new" ], [ "Contacted", "contacted" ], [ "Qualified", "qualified" ], [ "Disqualified", "disqualified" ] ]
  SOURCES = [ [ "Web Lead", "web" ], [ "Phone", "phone" ], [ "Referral", "referral" ], [ "Conference", "conference" ] ]
  INTERESTS = [ [ "Web Application", "web_app" ], [ "IOS", "ios" ] ]

  # Filtering scopes
  scope :search_by_name, ->(name) { where("first_name ILIKE :name OR last_name ILIKE :name", name: "%#{sanitize_sql_like(name)}%") }
  scope :search_by_company, ->(company) { where("company ILIKE :company", company: "%#{sanitize_sql_like(company)}%") }
  scope :by_email, ->(email) { where("email ILIKE :email", email: "%#{sanitize_sql_like(email)}%") }
  scope :created_since, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }
  scope :with_status, ->(status) { where(lead_status: status) }

  class << self
    def status
      STATUS
    end

    def sources
      SOURCES
    end

    def interests
      INTERESTS
    end
  end

  def full_name
    return first_name if last_name.blank?
    "#{first_name} #{last_name}"
  end
end
