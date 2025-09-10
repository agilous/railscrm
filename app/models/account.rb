class Account < ApplicationRecord
  validates_presence_of :name, :phone
  validates :name, uniqueness: true
end
