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
      expect(lead.notes.first.leads).to include(lead)
    end
  end

  describe 'scopes' do
    # Use around blocks to ensure complete isolation for each test
    around do |example|
      Lead.transaction do
        Lead.delete_all
        example.run
        raise ActiveRecord::Rollback # Roll back after each test
      end
    end

    let!(:unique_john) { create(:lead, first_name: 'UniqueJohn', last_name: 'UniqueDoe', company: 'XYZ Corp', lead_status: 'new', created_at: 3.days.ago) }
    let!(:unique_jane) { create(:lead, first_name: 'UniqueJane', last_name: 'UniqueSmith', company: 'Beta LLC', lead_status: 'contacted', created_at: 1.day.ago) }
    let!(:unique_bob) { create(:lead, first_name: 'UniqueBob', last_name: 'UniqueJohnson', company: 'Acme Industries', lead_status: 'qualified', created_at: Date.tomorrow.beginning_of_day) }

    describe '.search_by_name' do
      it 'returns all leads when query is blank' do
        expect(Lead.search_by_name('')).to match_array([ unique_john, unique_jane, unique_bob ])
        expect(Lead.search_by_name(nil)).to match_array([ unique_john, unique_jane, unique_bob ])
      end

      it 'searches by first name' do
        expect(Lead.search_by_name('UniqueJohn')).to match_array([ unique_john, unique_bob ]) # "UniqueJohn" matches both "UniqueJohn" and "UniqueJohnson"
        expect(Lead.search_by_name('uniquejane')).to contain_exactly(unique_jane)
      end

      it 'searches by last name' do
        expect(Lead.search_by_name('UniqueDoe')).to contain_exactly(unique_john)
        expect(Lead.search_by_name('uniquesmith')).to contain_exactly(unique_jane)
      end

      it 'searches by full name' do
        expect(Lead.search_by_name('UniqueJohn UniqueDoe')).to contain_exactly(unique_john)
        expect(Lead.search_by_name('uniquejane uniquesmith')).to contain_exactly(unique_jane)
      end

      it 'supports partial matching' do
        expect(Lead.search_by_name('UniqueJo')).to match_array([ unique_john, unique_bob ]) # Both match because "UniqueJohn" and "UniqueJohnson" contain "UniqueJo"
        expect(Lead.search_by_name('UniqueBo')).to contain_exactly(unique_bob)
      end

      it 'is case insensitive' do
        expect(Lead.search_by_name('UNIQUEJOHN')).to match_array([ unique_john, unique_bob ]) # Case insensitive match for both
        expect(Lead.search_by_name('uniquedoe')).to contain_exactly(unique_john)
      end
    end

    describe '.search_by_company' do
      it 'returns all leads when query is blank' do
        expect(Lead.search_by_company('')).to match_array([ unique_john, unique_jane, unique_bob ])
        expect(Lead.search_by_company(nil)).to match_array([ unique_john, unique_jane, unique_bob ])
      end

      it 'searches by exact company name' do
        expect(Lead.search_by_company('XYZ Corp')).to contain_exactly(unique_john)
        expect(Lead.search_by_company('Beta LLC')).to contain_exactly(unique_jane)
      end

      it 'supports partial matching' do
        expect(Lead.search_by_company('Acme')).to contain_exactly(unique_bob)
        expect(Lead.search_by_company('Corp')).to contain_exactly(unique_john)
      end

      it 'is case insensitive' do
        expect(Lead.search_by_company('ACME')).to contain_exactly(unique_bob)
        expect(Lead.search_by_company('beta')).to contain_exactly(unique_jane)
      end
    end

    describe '.created_before' do
      it 'returns all leads when date is blank' do
        expect(Lead.created_before('')).to match_array([ unique_john, unique_jane, unique_bob ])
        expect(Lead.created_before(nil)).to match_array([ unique_john, unique_jane, unique_bob ])
      end

      it 'filters leads created before the given date' do
        expect(Lead.created_before(2.days.ago.to_date)).to contain_exactly(unique_john)
        expect(Lead.created_before(Date.current)).to match_array([ unique_john, unique_jane ])
      end

      it 'includes leads created on the same day but before end of day' do
        today_lead = create(:lead, created_at: Date.current.beginning_of_day)
        expect(Lead.created_before(Date.current)).to include(today_lead)
      end
    end

    describe '.created_since' do
      it 'returns all leads when date is blank' do
        expect(Lead.created_since('')).to match_array([ unique_john, unique_jane, unique_bob ])
        expect(Lead.created_since(nil)).to match_array([ unique_john, unique_jane, unique_bob ])
      end

      it 'filters leads created since the given date' do
        expect(Lead.created_since(Date.tomorrow)).to contain_exactly(unique_bob)
        expect(Lead.created_since(2.days.ago.to_date)).to match_array([ unique_jane, unique_bob ])
      end

      it 'includes leads created on the same day from beginning of day' do
        today_lead = create(:lead, created_at: Date.current.end_of_day)
        expect(Lead.created_since(Date.current)).to include(today_lead)
      end
    end

    describe '.with_status' do
      it 'returns all leads when status is blank' do
        expect(Lead.with_status('')).to match_array([ unique_john, unique_jane, unique_bob ])
        expect(Lead.with_status(nil)).to match_array([ unique_john, unique_jane, unique_bob ])
      end

      it 'filters leads by status' do
        expect(Lead.with_status('new')).to contain_exactly(unique_john)
        expect(Lead.with_status('contacted')).to contain_exactly(unique_jane)
        expect(Lead.with_status('qualified')).to contain_exactly(unique_bob)
      end

      it 'returns empty result for non-existent status' do
        expect(Lead.with_status('nonexistent')).to be_empty
      end
    end

    describe 'scope chaining' do
      it 'allows chaining multiple scopes' do
        result = Lead.search_by_company('XYZ').with_status('new')
        expect(result).to contain_exactly(unique_john)
      end

      it 'chains date and name filters' do
        result = Lead.search_by_name('UniqueJane').created_since(2.days.ago.to_date)
        expect(result).to contain_exactly(unique_jane)
      end
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
