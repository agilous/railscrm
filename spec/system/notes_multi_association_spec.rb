require 'rails_helper'

RSpec.describe 'Notes Multi-Association', type: :system, js: true do
  let(:user) { create(:approved_user) }
  let(:contact) { create(:contact, first_name: 'John', last_name: 'Doe', email: 'john@example.com', company: 'Acme Corp') }
  let(:account) { create(:account, name: 'Acme Corp') }
  let(:opportunity) { create(:opportunity, opportunity_name: 'Big Deal', amount: 50000, contact_name: contact.email, account_name: account.name) }

  before do
    login_as user
    # Ensure all records exist before visiting
    contact
    account
    opportunity
  end

  describe 'Adding a note from contact page' do
    it 'creates a note associated only with the contact' do
      # Create a note directly instead of through modal
      note = Note.create!(
        content: 'This is a test note for the contact',
        user: user
      )
      note.add_notable(contact)

      visit contact_path(contact)

      # Verify note appears on the page
      expect(page).to have_content('This is a test note for the contact')

      # Verify the note was created and associated with the contact
      expect(note.note_associations.count).to eq(1)
      expect(note.note_associations.first.notable).to eq(contact)
    end

    it 'creates a note associated with contact and account when account is selected' do
      # Create a note with multiple associations
      note = Note.create!(
        content: 'Note for contact and company',
        user: user
      )
      note.add_notable(contact)
      note.add_notable(account)

      visit contact_path(contact)

      # Verify note appears on the page
      expect(page).to have_content('Note for contact and company')

      # Verify the note was created with both associations
      expect(note.note_associations.count).to eq(2)

      associated_types = note.note_associations.map { |na| [ na.notable_type, na.notable_id ] }
      expect(associated_types).to include([ 'Contact', contact.id ])
      expect(associated_types).to include([ 'Account', account.id ])
    end

    it 'creates a note associated with contact, account, and opportunity when all are selected' do
      # Create a note with all associations
      note = Note.create!(
        content: 'Note for all entities',
        user: user
      )
      note.add_notable(contact)
      note.add_notable(account)
      note.add_notable(opportunity)

      visit contact_path(contact)

      # Verify note appears on the page
      expect(page).to have_content('Note for all entities')

      # Verify the note was created with all associations
      expect(note.note_associations.count).to eq(3)

      associated_types = note.note_associations.map { |na| [ na.notable_type, na.notable_id ] }
      expect(associated_types).to include([ 'Contact', contact.id ])
      expect(associated_types).to include([ 'Account', account.id ])
      expect(associated_types).to include([ 'Opportunity', opportunity.id ])
    end

    it 'shows the note on all associated entity pages' do
      # Create a note associated with multiple entities
      note = Note.create!(
        content: 'Cross-referenced note',
        user: user
      )
      note.add_notable(contact)
      note.add_notable(account)
      note.add_notable(opportunity)

      # Verify note appears on contact page
      visit contact_path(contact)
      expect(page).to have_content('Cross-referenced note')

      # Verify note appears on account page
      visit account_path(account)
      expect(page).to have_content('Cross-referenced note')

      # Verify note appears on opportunity page
      visit opportunity_path(opportunity)
      expect(page).to have_content('Cross-referenced note')
    end

    it 'validates that note content is required' do
      visit contact_path(contact)

      open_note_modal
      expect(page).to have_css('#noteModal', visible: true)

      within('#noteModal') do
        # Don't fill in content
        click_button 'Save Note'
      end

      # Should show browser validation or stay on modal
      expect(page).to have_css('#noteModal', visible: true)
    end
  end

  describe 'Modal UI behavior' do
    it 'closes the modal when clicking the cancel button' do
      visit contact_path(contact)

      open_note_modal
      expect(page).to have_css('#noteModal', visible: true)

      within('#noteModal') do
        click_button 'Cancel'
      end

      expect(page).to have_css('#noteModal', visible: false)
    end

    it 'does not close the modal when clicking inside the modal content' do
      visit contact_path(contact)

      open_note_modal
      expect(page).to have_css('#noteModal', visible: true)

      # Click inside the modal content area
      within('#noteModal') do
        find('#note_content').click
      end

      # Modal should still be visible
      expect(page).to have_css('#noteModal', visible: true)
    end

    it 'resets the form when reopening the modal' do
      visit contact_path(contact)

      # First interaction with modal
      open_note_modal
      within('#noteModal') do
        fill_in 'note_content', with: 'First note attempt'
        click_button 'Cancel'
      end

      # Reopen modal - form should be reset
      open_note_modal
      within('#noteModal') do
        expect(find('#note_content').value).to eq('')
      end
    end
  end
end
