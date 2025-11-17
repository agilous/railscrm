require 'rails_helper'

RSpec.describe "Note Multi-Associations", type: :model do
  let(:note) { create(:note) }
  let(:contact) { create(:contact) }
  let(:opportunity) { create(:opportunity) }
  let(:account) { create(:account) }
  let(:lead) { create(:lead) }

  describe Note do
    describe 'associations' do
      it { is_expected.to have_many(:note_associations).dependent(:destroy) }
      it { is_expected.to have_many(:contacts).through(:note_associations) }
      it { is_expected.to have_many(:leads).through(:note_associations) }
      it { is_expected.to have_many(:opportunities).through(:note_associations) }
      it { is_expected.to have_many(:accounts).through(:note_associations) }
    end

    describe '#add_notable' do
      it 'adds a new association to a contact' do
        expect {
          note.add_notable(contact)
        }.to change(note.note_associations, :count).by(1)

        expect(note.contacts).to include(contact)
      end

      it 'does not duplicate existing associations' do
        note.add_notable(contact)

        expect {
          note.add_notable(contact)
        }.not_to change(note.note_associations, :count)
      end

      it 'can add multiple different associations' do
        note.add_notable(contact)
        note.add_notable(opportunity)
        note.add_notable(account)

        expect(note.note_associations.count).to eq(3)
        expect(note.contacts).to include(contact)
        expect(note.opportunities).to include(opportunity)
        expect(note.accounts).to include(account)
      end
    end

    describe '#all_notables' do
      it 'returns all associated entities' do
        note.add_notable(contact)
        note.add_notable(opportunity)
        note.add_notable(lead)

        notables = note.all_notables

        expect(notables).to include(contact, opportunity, lead)
        expect(notables.count).to eq(3)
      end

      it 'returns empty array when no associations' do
        expect(note.all_notables).to eq([])
      end
    end
  end

  describe 'Entity associations to notes' do
    describe Contact do
      it 'has many notes through note_associations' do
        note1 = create(:note)
        note2 = create(:note)

        note1.add_notable(contact)
        note2.add_notable(contact)

        expect(contact.notes).to include(note1, note2)
        expect(contact.notes.count).to eq(2)
      end

      it 'destroys note_associations when contact is destroyed' do
        note.add_notable(contact)

        expect {
          contact.destroy
        }.to change(NoteAssociation, :count).by(-1)

        # Note itself should still exist
        expect(Note.exists?(note.id)).to be true
      end
    end

    describe Opportunity do
      it 'has many notes through note_associations' do
        note.add_notable(opportunity)

        expect(opportunity.notes).to include(note)
      end
    end

    describe Account do
      it 'has many notes through note_associations' do
        note.add_notable(account)

        expect(account.notes).to include(note)
      end
    end

    describe Lead do
      it 'has many notes through note_associations' do
        note.add_notable(lead)

        expect(lead.notes).to include(note)
      end
    end
  end

  describe 'Real-world scenario: Pipedrive-style multi-association' do
    it 'allows a note to be associated with both a contact and their deal' do
      # Create relationships
      contact.update(email: 'dan@busken.com')
      opportunity.update(contact_name: 'dan@busken.com')

      # Create note and associate with both
      note = Note.create!(content: "Discussed pricing for enterprise plan")
      note.add_notable(contact)
      note.add_notable(opportunity)

      # Verify note appears in both places
      expect(contact.notes).to include(note)
      expect(opportunity.notes).to include(note)

      # Verify the note knows about both associations
      expect(note.all_notables).to contain_exactly(contact, opportunity)
    end

    it 'handles complex multi-entity associations' do
      # Setup: Contact works at Account, has an Opportunity
      contact.update(company: account.name, email: 'test@example.com')
      opportunity.update(
        account_name: account.name,
        contact_name: 'test@example.com'
      )

      # Create a note about a meeting
      meeting_note = Note.create!(
        content: "Q4 planning meeting with entire team"
      )

      # Associate with all relevant entities
      meeting_note.add_notable(contact)
      meeting_note.add_notable(opportunity)
      meeting_note.add_notable(account)

      # Verify visibility from all angles
      expect(contact.notes).to include(meeting_note)
      expect(opportunity.notes).to include(meeting_note)
      expect(account.notes).to include(meeting_note)

      # Verify association count
      expect(meeting_note.note_associations.count).to eq(3)
    end
  end

  describe 'Migration from old polymorphic to new multi-association' do
    it 'supports new multi-association approach' do
      # Create a note without associations
      migrated_note = Note.create!(
        content: "Migrated note"
      )

      # Add associations using the new method
      migrated_note.add_notable(contact)
      expect(migrated_note.contacts).to include(contact)

      # Can add multiple associations
      migrated_note.add_notable(opportunity)
      expect(migrated_note.opportunities).to include(opportunity)

      # All associations are available
      expect(migrated_note.all_notables).to contain_exactly(contact, opportunity)
    end
  end
end
