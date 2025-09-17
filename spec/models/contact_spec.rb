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

  describe 'scopes' do
    let!(:john_doe) { create(:contact, first_name: 'John', last_name: 'Doe', email: 'john@example.com', company: 'Acme Corp') }
    let!(:jane_smith) { create(:contact, first_name: 'Jane', last_name: 'Smith', email: 'jane@test.com', company: 'Tech Inc') }
    let!(:bob_johnson) { create(:contact, first_name: 'Bob', last_name: 'Johnson', email: 'bob@example.com', company: 'Acme Corp') }

    describe '.by_name' do
      it 'finds contacts by first name' do
        results = Contact.by_name('John')

        expect(results).to include(john_doe, bob_johnson)
        expect(results).not_to include(jane_smith)
      end

      it 'finds contacts by last name' do
        results = Contact.by_name('Smith')

        expect(results).to include(jane_smith)
        expect(results).not_to include(john_doe, bob_johnson)
      end

      it 'is case insensitive' do
        results = Contact.by_name('JOHN')

        expect(results).to include(john_doe, bob_johnson)
      end

      it 'handles SQL special characters safely' do
        results = Contact.by_name('%')

        expect(results).to be_empty
      end
    end

    describe '.by_company' do
      it 'finds contacts by company name' do
        results = Contact.by_company('Acme')

        expect(results).to include(john_doe, bob_johnson)
        expect(results).not_to include(jane_smith)
      end

      it 'is case insensitive' do
        results = Contact.by_company('ACME')

        expect(results).to include(john_doe, bob_johnson)
      end

      it 'handles SQL special characters safely' do
        results = Contact.by_company('_')

        expect(results).to be_empty
      end
    end

    describe '.by_email' do
      it 'finds contacts by email' do
        results = Contact.by_email('example.com')

        expect(results).to include(john_doe, bob_johnson)
        expect(results).not_to include(jane_smith)
      end

      it 'is case insensitive' do
        results = Contact.by_email('EXAMPLE.COM')

        expect(results).to include(john_doe, bob_johnson)
      end
    end

    describe '.created_since' do
      it 'finds contacts created after a given date' do
        john_doe.update_column(:created_at, 3.days.ago)
        jane_smith.update_column(:created_at, 1.day.ago)
        bob_johnson.update_column(:created_at, 5.days.ago)

        results = Contact.created_since(2.days.ago)

        expect(results).to include(jane_smith)
        expect(results).not_to include(john_doe, bob_johnson)
      end
    end

    describe '.created_before' do
      it 'finds contacts created before a given date' do
        john_doe.update_column(:created_at, 5.days.ago)
        jane_smith.update_column(:created_at, 1.day.ago)
        bob_johnson.update_column(:created_at, 3.days.ago)

        results = Contact.created_before(2.days.ago)

        expect(results).to include(john_doe, bob_johnson)
        expect(results).not_to include(jane_smith)
      end
    end

    describe 'chaining scopes' do
      it 'allows combining multiple scopes' do
        results = Contact.by_company('Acme').by_name('Doe')

        expect(results).to include(john_doe)
        expect(results).not_to include(jane_smith, bob_johnson)
      end
    end
  end
end
