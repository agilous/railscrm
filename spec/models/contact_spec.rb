require 'rails_helper'

RSpec.describe Contact, type: :model do
  subject(:contact) { build(:contact, first_name: 'Jane', last_name: 'Smith') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }

    describe 'email format validation' do
      it 'accepts valid email addresses' do
        contact.email = 'user@example.com'

        expect(contact).to be_valid
      end

      it 'rejects invalid email addresses' do
        contact.email = 'invalid-email'

        expect(contact).not_to be_valid
        expect(contact.errors[:email]).to include('Invalid e-mail address')
      end
    end
  end

  describe '#full_name' do
    context 'with both first and last name' do
      it 'returns concatenated name' do
        result = contact.full_name

        expect(result).to eq('Jane Smith')
      end
    end

    context 'with missing last name' do
      before { contact.last_name = nil }

      it 'returns only first name' do
        result = contact.full_name

        expect(result).to eq('Jane')
      end
    end

    context 'with blank last name' do
      before { contact.last_name = '' }

      it 'returns only first name' do
        result = contact.full_name

        expect(result).to eq('Jane')
      end
    end
  end

  describe 'address fields' do
    it 'can store complete address information' do
      contact.address = '123 Main St'
      contact.city = 'Anytown'
      contact.state = 'NY'
      contact.zip = '12345'

      expect(contact).to be_valid
      expect(contact.address).to eq('123 Main St')
      expect(contact.city).to eq('Anytown')
      expect(contact.state).to eq('NY')
      expect(contact.zip).to eq('12345')
    end
  end
end
