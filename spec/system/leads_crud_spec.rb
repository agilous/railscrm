require 'rails_helper'

RSpec.describe 'Leads CRUD', type: :system do
  let(:user) { create(:approved_user) }

  before do
    login_as user
  end

  describe 'Index page' do
    let!(:lead1) { create(:lead, first_name: 'John', last_name: 'Doe', company: 'Acme Corp') }
    let!(:lead2) { create(:lead, first_name: 'Jane', last_name: 'Smith', company: 'Tech Inc') }

    it 'displays all leads' do
      visit leads_path

      expect(page).to have_content('Leads')
      expect(page).to have_content('John Doe')
      expect(page).to have_content('Jane Smith')
      expect(page).to have_content('Acme Corp')
      expect(page).to have_content('Tech Inc')
    end

    it 'has a create lead button' do
      visit leads_path

      expect(page).to have_link('Create Lead', href: new_lead_path)
    end

    it 'allows navigation to individual leads' do
      visit leads_path

      click_link 'John Doe'
      expect(page).to have_current_path(lead_path(lead1))
    end
  end

  describe 'Show page' do
    let!(:lead) { create(:lead, first_name: 'John', last_name: 'Doe', company: 'Acme Corp', email: 'john@acme.com') }

    it 'displays lead details' do
      visit lead_path(lead)

      expect(page).to have_content('John Doe')
      expect(page).to have_content('Acme Corp')
      expect(page).to have_content('john@acme.com')
    end

    it 'has edit and convert buttons' do
      visit lead_path(lead)

      expect(page).to have_link('Edit', href: edit_lead_path(lead))
      expect(page).to have_link('Convert Lead')
    end
  end

  describe 'New page' do
    it 'displays the form' do
      visit new_lead_path

      expect(page).to have_content('Create New Lead')
      expect(page).to have_field('First name')
      expect(page).to have_field('Last name')
      expect(page).to have_field('Email')
      expect(page).to have_field('Company')
    end

    it 'creates a new lead with valid data' do
      visit new_lead_path

      fill_in 'First name', with: 'Test'
      fill_in 'Last name', with: 'User'
      fill_in 'Email', with: 'test@example.com'
      fill_in 'Company', with: 'Test Corp'
      select user.email, from: 'Lead owner'

      click_button 'Create Lead'

      expect(page).to have_content('New Lead Created')
      expect(page).to have_content('Test User')
    end

    it 'shows errors for invalid data' do
      visit new_lead_path

      click_button 'Create Lead'

      expect(page).to have_content("can't be blank")
    end
  end

  describe 'Edit page' do
    let!(:lead) { create(:lead, first_name: 'John', last_name: 'Doe') }

    it 'displays the form with current data' do
      visit edit_lead_path(lead)

      expect(page).to have_content('Edit Lead: John Doe')
      expect(page).to have_field('First name', with: 'John')
      expect(page).to have_field('Last name', with: 'Doe')
    end

    it 'updates the lead with valid data' do
      visit edit_lead_path(lead)

      fill_in 'First name', with: 'Updated'
      click_button 'Update Lead'

      expect(page).to have_content('Lead Updated')
      expect(page).to have_content('Updated Doe')
    end
  end

  # Delete functionality is tested in request specs due to Turbo confirm dialog issues with Selenium

  describe 'Notes functionality' do
    let!(:lead) { create(:lead, first_name: 'John', last_name: 'Doe') }

    it 'allows adding notes to a lead' do
      visit lead_path(lead)

      click_button 'New Note'
      fill_in 'Note', with: 'This is a test note'
      click_button 'Add Note'

      expect(page).to have_content('This is a test note')
    end
  end
end
