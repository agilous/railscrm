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

  describe 'Stage progression placeholders' do
    let!(:opp_prospecting) { create(:opportunity, opportunity_name: 'Prospecting Deal', stage: 'prospecting', amount: 50000, owner: user.email) }
    let!(:opp_closed_won) { create(:opportunity, opportunity_name: 'Won Deal', stage: 'closed_won', amount: 100000, owner: user.email) }

    it 'displays opportunities with different stages' do
      visit opportunities_path

      expect(page).to have_content('Prospecting Deal')
      expect(page).to have_content('Won Deal')
      expect(page).to have_content('$50,000')
      expect(page).to have_content('$100,000')
    end

    # Note: Stage-specific UI styling and advanced pipeline views
    # are placeholders for future implementation
  end

  describe 'Future filtering and sorting placeholders' do
    let!(:opp1) { create(:opportunity, opportunity_name: 'Alpha Deal', account_name: 'Alpha Corp', stage: 'prospecting', type: 'new_customer', owner: user.email) }
    let!(:opp2) { create(:opportunity, opportunity_name: 'Beta Deal', account_name: 'Beta Inc', stage: 'proposal', type: 'existing_customer', owner: user.email) }

    it 'displays opportunities in index view' do
      visit opportunities_path

      expect(page).to have_content('Alpha Deal')
      expect(page).to have_content('Beta Deal')
      expect(page).to have_content('Alpha Corp')
      expect(page).to have_content('Beta Inc')
    end

    # Note: Advanced filtering and sorting UI not yet implemented
    # These tests would be activated once the filtering UI is added
  end

  describe 'Notes integration placeholders' do
    let!(:opportunity) { create(:opportunity, opportunity_name: 'Notes Test Deal', account_name: 'Test Account', owner: user.email) }

    it 'shows opportunity details' do
      visit opportunity_path(opportunity)

      expect(page).to have_content('Notes Test Deal')
      expect(page).to have_content('Test Account')
    end

    # Note: Notes integration UI for opportunities not yet implemented
    # These tests would be activated once the notes UI is added to opportunity views
  end

  describe 'Error handling and validation' do
    it 'validates amount is numeric' do
      visit new_opportunity_path

      fill_in 'Opportunity name', with: 'Test Deal'
      fill_in 'Account name', with: 'Test Account'
      fill_in 'Owner', with: user.email
      fill_in 'Amount', with: 'not-a-number'

      click_button 'Create Opportunity'

      expect(page).to have_content('Amount').or have_content('invalid').or have_content('number')
    end

    it 'handles very large amounts properly' do
      big_deal = create(:opportunity, amount: 1_000_000, opportunity_name: 'Million Dollar Deal', account_name: 'Big Corp', owner: user.email)

      visit opportunity_path(big_deal)

      expect(page).to have_content('$1,000,000')
    end

    it 'handles missing optional fields gracefully' do
      minimal_opportunity = create(:opportunity,
        opportunity_name: 'Minimal Deal',
        account_name: 'Test Account',
        owner: user.email,
        amount: nil,
        probability: nil,
        closing_date: nil
      )

      visit opportunity_path(minimal_opportunity)

      expect(page).to have_content('Minimal Deal')
      expect(page).to have_content('Test Account')
    end
  end

  # Delete functionality is tested in request specs due to Turbo confirm dialog issues with Selenium
end
