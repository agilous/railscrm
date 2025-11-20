class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Validations
  validates_presence_of :email
  validates_uniqueness_of :email
  validates_presence_of :encrypted_password

  # Associations
  has_many :leads, foreign_key: "assigned_to_id"
  has_many :activities

  def full_name
    return first_name if last_name.blank?
    "#{first_name} #{last_name}"
  end

  # Override Devise methods for approval workflow
  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super
    end
  end
end
