class Contact < ApplicationRecord
  validates :email, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP,
                             message: "Invalid e-mail address" }
  validates_presence_of :first_name, :last_name, :email

  def full_name
    return first_name if last_name.blank?
    "#{first_name} #{last_name}"
  end
end
