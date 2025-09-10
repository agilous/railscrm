require 'rails_helper'

RSpec.describe Lead, type: :model do
  subject(:lead) { build(:lead, first_name: 'Bob', last_name: 'Johnson') }

  describe 'associations' do
    it { is_expected.to belong_to(:assigned_to).class_name('User') }
    it { is_expected.to have_many(:notes) }
    it { is_expected.to accept_nested_attributes_for(:notes).allow_destroy(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:lead_owner) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }

    describe 'email format validation' do
      it 'accepts valid email addresses' do
        lead.email = 'lead@example.com'

        expect(lead).to be_valid
      end

      it 'rejects invalid email addresses' do
        lead.email = 'invalid-email'

        expect(lead).not_to be_valid
        expect(lead.errors[:email]).to include('Invalid e-mail address')
      end
    end
  end

  describe '.status' do
    it 'returns array of status options' do
      statuses = Lead.status

      expect(statuses).to eq([ [ 'New', 'new' ], [ 'Contacted', 'contacted' ], [ 'Qualified', 'qualified' ], [ 'Disqualified', 'disqualified' ] ])
    end
  end

  describe '.sources' do
    it 'returns array of source options' do
      sources = Lead.sources

      expect(sources).to eq([ [ 'Web Lead', 'web' ], [ 'Phone', 'phone' ], [ 'Referral', 'referral' ], [ 'Conference', 'conference' ] ])
    end
  end

  describe '.interests' do
    it 'returns array of interest options' do
      interests = Lead.interests

      expect(interests).to eq([ [ 'Web Application', 'web_app' ], [ 'IOS', 'ios' ] ])
    end
  end

  describe '#full_name' do
    context 'with both first and last name' do
      it 'returns concatenated name' do
        result = lead.full_name

        expect(result).to eq('Bob Johnson')
      end
    end

    context 'with missing last name' do
      before { lead.last_name = nil }

      it 'returns only first name' do
        result = lead.full_name

        expect(result).to eq('Bob')
      end
    end

    context 'with blank last name' do
      before { lead.last_name = '' }

      it 'returns only first name' do
        result = lead.full_name

        expect(result).to eq('Bob')
      end
    end
  end

  describe 'status traits' do
    it 'can be created with contacted status' do
      lead = build(:lead, :contacted)

      expect(lead.lead_status).to eq('contacted')
    end

    it 'can be created with qualified status' do
      lead = build(:lead, :qualified)

      expect(lead.lead_status).to eq('qualified')
    end

    it 'can be created with disqualified status' do
      lead = build(:lead, :disqualified)

      expect(lead.lead_status).to eq('disqualified')
    end
  end

  describe 'source traits' do
    it 'can be created from phone source' do
      lead = build(:lead, :from_phone)

      expect(lead.lead_source).to eq('phone')
    end

    it 'can be created from referral source' do
      lead = build(:lead, :from_referral)

      expect(lead.lead_source).to eq('referral')
    end
  end

  describe 'interest traits' do
    it 'can be interested in iOS' do
      lead = build(:lead, :interested_in_ios)

      expect(lead.interested_in).to eq('ios')
    end
  end

  describe 'nested attributes for notes' do
    it 'can be created with associated notes' do
      lead = create(:lead, :with_notes, notes_count: 3)

      expect(lead.notes.count).to eq(3)
      expect(lead.notes.first).to be_a(Note)
      expect(lead.notes.first.notable).to eq(lead)
    end
  end

  describe 'contact fields inheritance' do
    it 'includes all contact-like fields' do
      lead = create(:lead,
                   first_name: 'Test',
                   last_name: 'Lead',
                   company: 'Test Co',
                   phone: '555-1234',
                   address: '123 Test St',
                   city: 'Test City',
                   state: 'TS',
                   zip: '12345')

      expect(lead.first_name).to eq('Test')
      expect(lead.last_name).to eq('Lead')
      expect(lead.company).to eq('Test Co')
      expect(lead.phone).to eq('555-1234')
      expect(lead.address).to eq('123 Test St')
      expect(lead.city).to eq('Test City')
      expect(lead.state).to eq('TS')
      expect(lead.zip).to eq('12345')
    end
  end
end
