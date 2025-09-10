require 'rails_helper'

RSpec.describe Note, type: :model do
  subject(:note) { build(:note) }

  describe 'associations' do
    it { is_expected.to belong_to(:notable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'polymorphic associations' do
    it 'can belong to a lead' do
      lead = create(:lead)
      note = create(:note, :for_lead, notable: lead)

      expect(note.notable).to eq(lead)
      expect(note.notable_type).to eq('Lead')
      expect(note.notable_id).to eq(lead.id)
    end

    it 'can belong to a contact' do
      contact = create(:contact)
      note = create(:note, :for_contact, notable: contact)

      expect(note.notable).to eq(contact)
      expect(note.notable_type).to eq('Contact')
      expect(note.notable_id).to eq(contact.id)
    end

    it 'can belong to an account' do
      account = create(:account)
      note = create(:note, :for_account, notable: account)

      expect(note.notable).to eq(account)
      expect(note.notable_type).to eq('Account')
      expect(note.notable_id).to eq(account.id)
    end
  end

  describe 'content validation' do
    it 'is valid with content' do
      note = build(:note, content: 'Important note content')

      expect(note).to be_valid
    end

    it 'is invalid without content' do
      note = build(:note, content: nil)

      expect(note).not_to be_valid
      expect(note.errors[:content]).to include("can't be blank")
    end

    it 'is invalid with blank content' do
      note = build(:note, content: '')

      expect(note).not_to be_valid
      expect(note.errors[:content]).to include("can't be blank")
    end
  end

  describe 'content length traits' do
    it 'can be created with short content' do
      note = build(:note, :short)

      expect(note.content).to eq('Short note')
      expect(note).to be_valid
    end

    it 'can be created with long content' do
      note = build(:note, :long)

      expect(note.content.length).to be > 100
      expect(note).to be_valid
    end
  end

  describe 'default factory behavior' do
    it 'defaults to being associated with a lead' do
      note = build(:note)

      expect(note.notable).to be_a(Lead)
    end
  end

  describe 'factory traits' do
    it 'for_lead trait creates note associated with lead' do
      note = build(:note, :for_lead)

      expect(note.notable).to be_a(Lead)
    end

    it 'for_contact trait creates note associated with contact' do
      note = build(:note, :for_contact)

      expect(note.notable).to be_a(Contact)
    end

    it 'for_account trait creates note associated with account' do
      note = build(:note, :for_account)

      expect(note.notable).to be_a(Account)
    end
  end
end
