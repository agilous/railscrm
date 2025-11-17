require 'rails_helper'

RSpec.describe 'User Authentication', type: :system do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  before do
    driven_by(:rack_test)
  end

  describe 'successful login' do
    it 'allows a user to sign in with valid credentials' do
      visit new_user_session_path

      expect(page).to have_content('Sign in to your account')

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_content('Signed in successfully.')
    end

    it 'remembers user when remember me is checked' do
      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      check 'Remember me'

      click_button 'Sign in'

      expect(page).to have_content('Signed in successfully.')
    end
  end

  describe 'failed login attempts' do
    it 'shows error for invalid email' do
      visit new_user_session_path

      fill_in 'Email', with: 'nonexistent@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_content('Invalid Email or password.')
      expect(page).to have_current_path(new_user_session_path)
    end

    it 'shows error for invalid password' do
      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'wrongpassword'

      click_button 'Sign in'

      expect(page).to have_content('Invalid Email or password.')
      expect(page).to have_current_path(new_user_session_path)
    end

    it 'shows errors for blank fields' do
      visit new_user_session_path

      click_button 'Sign in'

      expect(page).to have_content('Invalid Email or password.')
    end
  end

  describe 'logout functionality' do
    it 'allows a user to sign out' do
      # First sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      expect(page).to have_content('Signed in successfully.')

      # Then sign out (using the logout path with DELETE method)
      page.driver.submit :delete, destroy_user_session_path, {}

      expect(page).to have_content('Signed out successfully.')
    end
  end

  describe 'navigation links' do
    it 'provides link to registration page' do
      visit new_user_session_path

      expect(page).to have_link('Sign up', href: new_user_registration_path)
    end

    it 'provides link to forgot password' do
      visit new_user_session_path

      expect(page).to have_link('Forgot your password?', href: new_user_password_path)
    end
  end

  describe 'session tracking' do
    it 'tracks sign in count and timestamps' do
      initial_sign_in_count = user.sign_in_count

      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      user.reload
      expect(user.sign_in_count).to eq(initial_sign_in_count + 1)
      expect(user.current_sign_in_at).to be_present
      expect(user.last_sign_in_at).to be_present
    end
  end
end
