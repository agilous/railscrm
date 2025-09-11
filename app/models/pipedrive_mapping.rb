class PipedriveMapping < ApplicationRecord
  validates :pipedrive_type, presence: true
  validates :pipedrive_id, presence: true
  validates :rails_id, presence: true

  validates :pipedrive_id, uniqueness: { scope: :pipedrive_type }
end
