require 'rails_helper'

RSpec.describe 'Opportunities CRUD', type: :system do
  let(:user) { create(:approved_user) }

  before do
    login_as user
  end

  describe 'Index page' do
    let!(:opp1) { create(:opportunity, opportunity_name: 'Big Deal', account_name: 'Enterprise Corp', amount: 100000) }
    let!(:opp2) { create(:opportunity, opportunity_name: 'Small Deal', account_name: 'Startup Inc', amount: 5000) }

    it 'displays all opportunities' do
      visit opportunities_path

      expect(page).to have_content('Opportunities')
      expect(page).to have_content('Big Deal')
      expect(page).to have_content('Small Deal')
      expect(page).to have_content('Enterprise Corp')
      expect(page).to have_content('Startup Inc')
      expect(page).to have_content('$100,000')
      expect(page).to have_content('$5,000')
    end

    it 'has a create opportunity button' do
      visit opportunities_path

      expect(page).to have_link('Create Opportunity', href: new_opportunity_path)
    end

    it 'allows navigation to individual opportunities' do
      visit opportunities_path

      click_link 'Big Deal'
      expect(page).to have_current_path(opportunity_path(opp1))
    end
  end

  describe 'Show page' do
    let!(:opportunity) { create(:opportunity, opportunity_name: 'Big Deal', account_name: 'Enterprise Corp', amount: 100000) }

    it 'displays opportunity details' do
      visit opportunity_path(opportunity)

      expect(page).to have_content('Big Deal')
      expect(page).to have_content('Enterprise Corp')
      expect(page).to have_content('$100,000')
    end

    it 'has edit button' do
      visit opportunity_path(opportunity)

      expect(page).to have_link('Edit', href: edit_opportunity_path(opportunity))
    end
  end

  describe 'New page' do
    it 'displays the form' do
      visit new_opportunity_path

      expect(page).to have_content('Create New Opportunity')
      expect(page).to have_field('Opportunity name')
      expect(page).to have_field('Account name')
      expect(page).to have_field('Owner')
      expect(page).to have_field('Amount')
    end

    it 'creates a new opportunity with valid data' do
      visit new_opportunity_path

      fill_in 'Opportunity name', with: 'Test Opportunity'
      fill_in 'Account name', with: 'Test Account'
      fill_in 'Owner', with: user.email
      fill_in 'Amount', with: '50000'

      click_button 'Create Opportunity'

      expect(page).to have_content('Test Opportunity')
    end

    it 'shows errors for invalid data' do
      visit new_opportunity_path

      click_button 'Create Opportunity'

      expect(page).to have_content("can't be blank")
    end
  end

  describe 'Edit page' do
    let!(:opportunity) { create(:opportunity, opportunity_name: 'Big Deal', account_name: 'Enterprise Corp') }

    it 'displays the form with current data' do
      visit edit_opportunity_path(opportunity)

      expect(page).to have_content('Edit Opportunity: Big Deal')
      expect(page).to have_field('Opportunity name', with: 'Big Deal')
      expect(page).to have_field('Account name', with: 'Enterprise Corp')
    end

    it 'updates the opportunity with valid data' do
      visit edit_opportunity_path(opportunity)

      fill_in 'Opportunity name', with: 'Updated Deal'
      click_button 'Update Opportunity'

      expect(page).to have_current_path(opportunity_path(opportunity))
      expect(page).to have_content('Updated Deal')
    end
  end

  describe 'Delete functionality' do
    let!(:opportunity) { create(:opportunity, opportunity_name: 'Big Deal', account_name: 'Enterprise Corp') }

    it 'deletes an opportunity from the index page' do
      visit opportunities_path

      accept_confirm do
        click_link 'Delete'
      end

      expect(page).not_to have_content('Big Deal')
    end
  end
end
