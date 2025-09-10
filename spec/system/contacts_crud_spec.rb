require 'rails_helper'

RSpec.describe 'Contacts CRUD', type: :system do
  let(:user) { create(:approved_user) }

  before do
    login_as user
  end

  describe 'Index page' do
    let!(:contact1) { create(:contact, first_name: 'Alice', last_name: 'Johnson', company: 'Design Co') }
    let!(:contact2) { create(:contact, first_name: 'Bob', last_name: 'Wilson', company: 'Dev Corp') }

    it 'displays all contacts' do
      visit contacts_path

      expect(page).to have_content('Contacts')
      expect(page).to have_content('Alice Johnson')
      expect(page).to have_content('Bob Wilson')
      expect(page).to have_content('Design Co')
      expect(page).to have_content('Dev Corp')
    end

    it 'has a create contact button' do
      visit contacts_path

      expect(page).to have_link('Create Contact', href: new_contact_path)
    end

    it 'allows navigation to individual contacts' do
      visit contacts_path

      click_link 'Alice Johnson'
      expect(page).to have_current_path(contact_path(contact1))
    end
  end

  describe 'Show page' do
    let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson', email: 'alice@example.com', phone: '555-1234') }

    it 'displays contact details' do
      visit contact_path(contact)

      expect(page).to have_content('Alice Johnson')
      expect(page).to have_content('alice@example.com')
      expect(page).to have_content('555-1234')
    end

    it 'has edit button' do
      visit contact_path(contact)

      expect(page).to have_link('Edit', href: edit_contact_path(contact))
    end
  end

  describe 'New page' do
    it 'displays the form' do
      visit new_contact_path

      expect(page).to have_content('Create New Contact')
      expect(page).to have_field('First name')
      expect(page).to have_field('Last name')
      expect(page).to have_field('Email')
      expect(page).to have_field('Company')
      expect(page).to have_field('Phone')
    end

    it 'creates a new contact with valid data' do
      visit new_contact_path

      fill_in 'First name', with: 'Test'
      fill_in 'Last name', with: 'Contact'
      fill_in 'Email', with: 'test@example.com'
      fill_in 'Company', with: 'Test Company'
      fill_in 'Phone', with: '555-9999'

      click_button 'Create Contact'

      expect(page).to have_current_path(contacts_path)
      expect(page).to have_content('Test Contact')
    end

    it 'shows errors for invalid data' do
      visit new_contact_path

      click_button 'Create Contact'

      expect(page).to have_content("can't be blank")
    end
  end

  describe 'Edit page' do
    let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson') }

    it 'displays the form with current data' do
      visit edit_contact_path(contact)

      expect(page).to have_content('Edit Contact: Alice Johnson')
      expect(page).to have_field('First name', with: 'Alice')
      expect(page).to have_field('Last name', with: 'Johnson')
    end

    it 'updates the contact with valid data' do
      visit edit_contact_path(contact)

      fill_in 'First name', with: 'Updated'
      click_button 'Update Contact'

      expect(page).to have_current_path(contact_path(contact))
      expect(page).to have_content('Updated Johnson')
    end
  end

  describe 'Delete functionality' do
    let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson') }

    it 'deletes a contact from the index page' do
      visit contacts_path

      accept_confirm do
        click_link 'Delete'
      end

      expect(page).not_to have_content('Alice Johnson')
    end
  end
end
