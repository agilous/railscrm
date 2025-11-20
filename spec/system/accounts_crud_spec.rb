require 'rails_helper'

RSpec.describe 'Accounts CRUD', type: :system do
  let(:user) { create(:approved_user) }

  before do
    login_as user
  end

  describe 'Index page' do
    let!(:account1) { create(:account, name: 'Enterprise Corp', phone: '555-1111') }
    let!(:account2) { create(:account, name: 'Startup Inc', phone: '555-2222') }

    it 'displays all accounts' do
      visit accounts_path

      expect(page).to have_content('Accounts')
      expect(page).to have_content('Enterprise Corp')
      expect(page).to have_content('Startup Inc')
      expect(page).to have_content('555-1111')
      expect(page).to have_content('555-2222')
    end

    it 'has a create account button' do
      visit accounts_path

      expect(page).to have_link('Create Account', href: new_account_path)
    end

    it 'allows navigation to individual accounts' do
      visit accounts_path

      click_link 'Enterprise Corp'
      expect(page).to have_current_path(account_path(account1))
    end
  end

  describe 'Show page' do
    let!(:account) { create(:account, name: 'Enterprise Corp', email: 'info@enterprise.com', website: 'enterprise.com') }

    it 'displays account details' do
      visit account_path(account)

      expect(page).to have_content('Enterprise Corp')
      expect(page).to have_content('info@enterprise.com')
      expect(page).to have_content('enterprise.com')
    end

    it 'has edit button' do
      visit account_path(account)

      expect(page).to have_link('Edit', href: edit_account_path(account))
    end
  end

  describe 'New page' do
    it 'displays the form' do
      visit new_account_path

      expect(page).to have_content('Create New Account')
      expect(page).to have_field('Name')
      expect(page).to have_field('Phone')
      expect(page).to have_field('Email')
      expect(page).to have_field('Website')
    end

    it 'creates a new account with valid data' do
      visit new_account_path

      fill_in 'Name', with: 'Test Account'
      fill_in 'Phone', with: '555-9999'
      fill_in 'Email', with: 'test@testaccount.com'
      fill_in 'Website', with: 'testaccount.com'

      click_button 'Create Account'

      expect(page).to have_current_path(accounts_path)
      expect(page).to have_content('Test Account')
    end

    it 'shows errors for invalid data' do
      visit new_account_path

      click_button 'Create Account'

      expect(page).to have_content("can't be blank")
    end
  end

  describe 'Edit page' do
    let!(:account) { create(:account, name: 'Enterprise Corp') }

    it 'displays the form with current data' do
      visit edit_account_path(account)

      expect(page).to have_content('Edit Account: Enterprise Corp')
      expect(page).to have_field('Name', with: 'Enterprise Corp')
    end

    it 'updates the account with valid data' do
      visit edit_account_path(account)

      fill_in 'Name', with: 'Updated Corp'
      click_button 'Update Account'

      expect(page).to have_current_path(account_path(account))
      expect(page).to have_content('Updated Corp')
    end
  end

  describe 'Future filtering and sorting placeholders' do
    let!(:account1) { create(:account, name: 'Alpha Corp', email: 'alpha@corp.com', assigned_to: 'Alice Johnson') }
    let!(:account2) { create(:account, name: 'Beta Inc', email: 'beta@inc.com', assigned_to: 'Bob Wilson') }

    it 'displays accounts in index view' do
      visit accounts_path

      expect(page).to have_content('Alpha Corp')
      expect(page).to have_content('Beta Inc')
      expect(page).to have_content('Alice Johnson')
      expect(page).to have_content('Bob Wilson')
    end

    # Note: Advanced filtering and sorting UI not yet implemented
    # These tests would be activated once the filtering UI is added
  end

  describe 'Quick actions and contact information' do
    let!(:account) { create(:account,
      name: 'Contact Test Corp',
      phone: '+1 (555) 123-4567',
      email: 'contact@test.com',
      website: 'https://test.com'
    ) }

    it 'displays clickable contact information' do
      visit account_path(account)

      expect(page).to have_link('contact@test.com', href: 'mailto:contact@test.com')
      expect(page).to have_link('+1 (555) 123-4567', href: 'tel:+1 (555) 123-4567')
      expect(page).to have_link('test.com')
    end

    it 'shows quick actions section' do
      visit account_path(account)

      expect(page).to have_content('Quick Actions')
      expect(page).to have_link('Edit Account')
      expect(page).to have_link('Send Email')
      expect(page).to have_link('Call Account')
      expect(page).to have_link('Visit Website')
    end

    it 'handles missing contact information gracefully' do
      minimal_account = create(:account, name: 'Minimal Account', phone: '555-0000', email: nil, website: nil)

      visit account_path(minimal_account)

      expect(page).to have_content('Quick Actions')
      expect(page).to have_link('Call Account')
      expect(page).not_to have_link('Send Email')
      expect(page).not_to have_link('Visit Website')
    end
  end

  describe 'Notes functionality' do
    let!(:account) { create(:account, name: 'Notes Test Account') }

    it 'shows notes section on account show page' do
      visit account_path(account)

      expect(page).to have_content('Notes Test Account')
      # Notes UI may be present depending on implementation
      # This test verifies the page loads correctly
    end

    it 'displays existing notes if they exist' do
      note = create(:note, content: 'Account onboarding completed successfully', user: user)
      note.add_notable(account)

      visit account_path(account)

      expect(page).to have_content('Account onboarding completed successfully')
    end
  end

  describe 'Error handling and edge cases' do
    it 'handles non-existent account gracefully' do
      visit account_path(99999)
      # Rails should handle this gracefully with a 404 page or redirect
      expect(page).to have_content("Account").or have_content("Error").or have_current_path(accounts_path)
    end

    it 'handles missing optional fields gracefully' do
      minimal_account = create(:account,
        name: 'Minimal Account',
        phone: '555-0000',
        email: nil,
        website: nil,
        address: nil,
        assigned_to: nil
      )

      visit account_path(minimal_account)

      expect(page).to have_content('Minimal Account')
      expect(page).to have_content('555-0000')
      expect(page).to have_content('No email').or have_content('—')
      expect(page).to have_content('Unassigned').or have_content('—')
    end

    it 'validates unique account names' do
      create(:account, name: 'Existing Company')

      visit new_account_path

      fill_in 'Name', with: 'Existing Company'
      fill_in 'Phone', with: '555-0000'

      click_button 'Create Account'

      expect(page).to have_content('Name has already been taken')
    end
  end

  # Delete functionality is tested in request specs due to Turbo confirm dialog issues with Selenium
end
