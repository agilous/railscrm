require 'rails_helper'

RSpec.describe Note, type: :model do
  subject(:note) { build(:note) }

  describe 'associations' do
    it { is_expected.to have_many(:note_associations).dependent(:destroy) }
    it { is_expected.to have_many(:contacts).through(:note_associations) }
    it { is_expected.to have_many(:leads).through(:note_associations) }
    it { is_expected.to have_many(:accounts).through(:note_associations) }
    it { is_expected.to have_many(:opportunities).through(:note_associations) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'multi-associations' do
    it 'can be associated with a lead' do
      lead = create(:lead)
      note = create(:note)
      note.add_notable(lead)

      expect(note.leads).to include(lead)
      expect(lead.notes).to include(note)
    end

    it 'can be associated with a contact' do
      contact = create(:contact)
      note = create(:note)
      note.add_notable(contact)

      expect(note.contacts).to include(contact)
      expect(contact.notes).to include(note)
    end

    it 'can be associated with an account' do
      account = create(:account)
      note = create(:note)
      note.add_notable(account)

      expect(note.accounts).to include(account)
      expect(account.notes).to include(note)
    end

    it 'can be associated with multiple entities' do
      lead = create(:lead)
      contact = create(:contact)
      account = create(:account)
      note = create(:note)

      note.add_notable(lead)
      note.add_notable(contact)
      note.add_notable(account)

      expect(note.all_notables).to contain_exactly(lead, contact, account)
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
    it 'creates a note without associations' do
      note = build(:note)

      expect(note.note_associations).to be_empty
      expect(note.all_notables).to be_empty
    end
  end

  describe 'factory traits' do
    it 'for_lead trait creates note that can be associated with lead' do
      lead = create(:lead)
      note = create(:note, :for_lead)
      note.add_notable(lead)

      expect(note.leads).to include(lead)
    end

    it 'for_contact trait creates note that can be associated with contact' do
      contact = create(:contact)
      note = create(:note, :for_contact)
      note.add_notable(contact)

      expect(note.contacts).to include(contact)
    end

    it 'for_account trait creates note that can be associated with account' do
      account = create(:account)
      note = create(:note, :for_account)
      note.add_notable(account)

      expect(note.accounts).to include(account)
    end
  end
end
