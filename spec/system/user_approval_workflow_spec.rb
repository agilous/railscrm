require 'rails_helper'

RSpec.describe 'User Approval Workflow', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'approved user login' do
    let(:approved_user) { create(:user, approved: true, email: 'approved@example.com', password: 'password123') }

    it 'allows approved user to sign in successfully' do
      visit new_user_session_path

      fill_in 'Email', with: approved_user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      expect(page).to have_content('Signed in successfully.')
    end
  end

  describe 'unapproved user login' do
    let(:unapproved_user) { create(:user, :unapproved, email: 'unapproved@example.com', password: 'password123') }

    it 'prevents unapproved user from signing in' do
      visit new_user_session_path

      fill_in 'Email', with: unapproved_user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      expect(page).to have_content('Your account is not approved yet.')
      expect(page).to have_current_path(new_user_session_path)
    end

    it 'shows appropriate message for unapproved account' do
      visit new_user_session_path

      fill_in 'Email', with: unapproved_user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Check that the custom inactive message is displayed
      expect(page).to have_content('Your account is not approved yet.')
      expect(page).not_to have_content('Invalid Email or password.')
    end
  end

  describe 'new user registration approval status' do
    it 'creates new users as approved by default' do
      visit new_user_registration_path

      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'

      click_button 'Sign up'

      user = User.find_by(email: 'newuser@example.com')
      expect(user.approved).to be true
    end

    it 'allows newly registered approved user to sign in immediately' do
      # Register user
      visit new_user_registration_path
      fill_in 'Email', with: 'immediate@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      fill_in 'First name', with: 'Jane'
      fill_in 'Last name', with: 'Doe'
      click_button 'Sign up'

      expect(page).to have_content('Welcome! You have signed up successfully.')

      # Sign out and sign back in
      page.driver.submit :delete, destroy_user_session_path, {}

      visit new_user_session_path
      fill_in 'Email', with: 'immediate@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      expect(page).to have_content('Signed in successfully.')
    end
  end

  describe 'admin functionality' do
    let(:admin_user) { create(:user, :admin, email: 'admin@example.com', password: 'password123') }
    let(:regular_user) { create(:user, email: 'regular@example.com', password: 'password123') }

    it 'creates admin users with admin flag' do
      expect(admin_user.admin).to be true
      expect(regular_user.admin).to be false
    end

    it 'allows admin users to sign in normally' do
      visit new_user_session_path

      fill_in 'Email', with: admin_user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      expect(page).to have_content('Signed in successfully.')
    end
  end

  describe 'user profile information' do
    let(:user) { create(:user,
                       first_name: 'John',
                       last_name: 'Doe',
                       company: 'Test Corp',
                       phone: '555-0123',
                       email: 'profile@example.com',
                       password: 'password123') }

    it 'maintains user profile information after approval workflow' do
      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Verify user information is preserved
      user.reload
      expect(user.first_name).to eq('John')
      expect(user.last_name).to eq('Doe')
      expect(user.company).to eq('Test Corp')
      expect(user.phone).to eq('555-0123')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'approval state changes' do
    let(:user) { create(:user, approved: true, email: 'changeable@example.com', password: 'password123') }

    it 'prevents login when user approval is revoked' do
      # First verify user can log in when approved
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
      expect(page).to have_content('Signed in successfully.')

      # Sign out
      page.driver.submit :delete, destroy_user_session_path, {}

      # Revoke approval
      user.update!(approved: false)

      # Try to log in again
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      expect(page).to have_content('Your account is not approved yet.')
    end
  end
end
