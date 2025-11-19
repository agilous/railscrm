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

  describe 'Lead conversion UI (Stubbed Implementation)' do
    let!(:lead) { create(:lead,
      first_name: 'Alice',
      last_name: 'Johnson',
      email: 'alice@design.com',
      company: 'Design Co',
      assigned_to: user
    ) }

    it 'has convert lead button on show page' do
      visit lead_path(lead)

      expect(page).to have_link('Convert Lead')
    end

    # Note: Convert lead functionality exists but is stubbed
    # The form and logic are implemented but show placeholder message
    # Tests for full conversion would be added once implementation is complete
  end

  describe 'Future filtering and sorting placeholders' do
    let!(:lead1) { create(:lead, first_name: 'Alice', last_name: 'Johnson', company: 'Design Co', lead_status: 'new', lead_source: 'web', assigned_to: user) }
    let!(:lead2) { create(:lead, first_name: 'Bob', last_name: 'Wilson', company: 'Dev Corp', lead_status: 'contacted', lead_source: 'phone', assigned_to: user) }

    it 'displays leads in index view' do
      visit leads_path

      expect(page).to have_content('Alice Johnson')
      expect(page).to have_content('Bob Wilson')
      expect(page).to have_content('Design Co')
      expect(page).to have_content('Dev Corp')
    end

    # Note: Filtering and sorting UI not yet implemented
    # These tests would be activated once the filtering UI is added
  end

  describe 'Web-to-Lead functionality' do
    it 'has external form route available' do
      # Verify the route exists
      expect { visit '/generate' }.not_to raise_error
    end

    # Note: External form functionality exists but detailed testing
    # is complex due to unauthenticated form requirements
    # Integration testing would cover the full flow
  end

  describe 'Notes functionality' do
    let!(:lead) { create(:lead, first_name: 'John', last_name: 'Doe') }

    it 'displays lead show page with notes section' do
      visit lead_path(lead)

      expect(page).to have_content('John Doe')
      expect(page).to have_content('Activity & Notes')

      # Notes functionality exists and can be tested when UI is properly implemented
    end
  end
end
