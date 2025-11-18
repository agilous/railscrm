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

  # Delete functionality is tested in request specs due to Turbo confirm dialog issues with Selenium
end
