require 'rails_helper'

RSpec.describe NoteAssociation, type: :model do
  let(:note) { create(:note) }
  let(:contact) { create(:contact) }
  let(:opportunity) { create(:opportunity) }

  describe 'associations' do
    it { should belong_to(:note) }
    it { should belong_to(:notable) }
  end

  describe 'validations' do
    it 'validates uniqueness of note_id scoped to notable' do
      # Create first association
      NoteAssociation.create!(
        note: note,
        notable: contact
      )

      # Attempt to create duplicate
      duplicate = NoteAssociation.new(
        note: note,
        notable: contact
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:note_id]).to include("has already been taken")
    end

    it 'allows same note to be associated with different notables' do
      NoteAssociation.create!(
        note: note,
        notable: contact
      )

      association2 = NoteAssociation.new(
        note: note,
        notable: opportunity
      )

      expect(association2).to be_valid
    end
  end

  describe 'polymorphic association' do
    it 'can associate with Contact' do
      association = NoteAssociation.create!(
        note: note,
        notable: contact
      )

      expect(association.notable_type).to eq('Contact')
      expect(association.notable_id).to eq(contact.id)
      expect(association.notable).to eq(contact)
    end

    it 'can associate with Lead' do
      lead = create(:lead)
      association = NoteAssociation.create!(
        note: note,
        notable: lead
      )

      expect(association.notable_type).to eq('Lead')
      expect(association.notable).to eq(lead)
    end

    it 'can associate with Opportunity' do
      association = NoteAssociation.create!(
        note: note,
        notable: opportunity
      )

      expect(association.notable_type).to eq('Opportunity')
      expect(association.notable).to eq(opportunity)
    end

    it 'can associate with Account' do
      account = create(:account)
      association = NoteAssociation.create!(
        note: note,
        notable: account
      )

      expect(association.notable_type).to eq('Account')
      expect(association.notable).to eq(account)
    end
  end
end
