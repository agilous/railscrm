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

  # Search scopes
  scope :search_by_name, ->(query) {
    return all if query.blank?
    where("first_name ILIKE :query OR last_name ILIKE :query OR CONCAT(first_name, ' ', last_name) ILIKE :query",
          query: "%#{query}%")
  }

  scope :search_by_company, ->(query) {
    return all if query.blank?
    where("company ILIKE ?", "%#{query}%")
  }

  scope :created_before, ->(date) {
    return all if date.blank?
    where("created_at < ?", date.to_date.end_of_day)
  }

  scope :created_since, ->(date) {
    return all if date.blank?
    where("created_at >= ?", date.to_date.beginning_of_day)
  }

  scope :with_status, ->(status) {
    return all if status.blank?
    where(lead_status: status)
  }

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
