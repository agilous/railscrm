require 'rails_helper'

RSpec.describe Account, type: :model do
  subject(:account) { build(:account) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'required fields' do
    it 'is valid with name and phone' do
      account = build(:account, name: 'Test Account', phone: '555-1234')

      expect(account).to be_valid
    end

    it 'is invalid without name' do
      account = build(:account, name: nil)

      expect(account).not_to be_valid
      expect(account.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without phone' do
      account = build(:account, phone: nil)

      expect(account).not_to be_valid
      expect(account.errors[:phone]).to include("can't be blank")
    end
  end

  describe 'uniqueness validation' do
    it 'prevents duplicate account names' do
      create(:account, name: 'Unique Account')
      duplicate_account = build(:account, name: 'Unique Account')

      expect(duplicate_account).not_to be_valid
      expect(duplicate_account.errors[:name]).to include('has already been taken')
    end
  end

  describe 'optional fields' do
    it 'can store complete account information' do
      account = build(:account,
                     name: 'Complete Account',
                     email: 'account@example.com',
                     website: 'https://example.com',
                     phone: '555-9876',
                     address: '789 Business Blvd',
                     city: 'Business City',
                     state: 'TX',
                     zip: '73301')

      expect(account).to be_valid
      expect(account.name).to eq('Complete Account')
      expect(account.email).to eq('account@example.com')
      expect(account.website).to eq('https://example.com')
      expect(account.phone).to eq('555-9876')
      expect(account.address).to eq('789 Business Blvd')
      expect(account.city).to eq('Business City')
      expect(account.state).to eq('TX')
      expect(account.zip).to eq('73301')
    end

    it 'is valid with only required fields' do
      account = build(:account, name: 'Minimal Account', phone: '555-0000', email: nil, website: nil)

      expect(account).to be_valid
    end
  end
end
