require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'successful registration' do
    it 'allows a user to register with valid information' do
      visit new_user_registration_path

      expect(page).to have_content('Create your account')

      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'
      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'
      fill_in 'Company', with: 'Test Company'
      fill_in 'Phone', with: '555-1234'

      click_button 'Sign up'

      expect(page).to have_content('Welcome! You have signed up successfully.')
      expect(User.count).to eq(1)

      user = User.last
      expect(user.email).to eq('newuser@example.com')
      expect(user.first_name).to eq('John')
      expect(user.last_name).to eq('Doe')
      expect(user.company).to eq('Test Company')
      expect(user.phone).to eq('555-1234')
    end
  end

  describe 'validation errors' do
    it 'shows errors for invalid registration data' do
      visit new_user_registration_path

      click_button 'Sign up'

      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Password can't be blank")
      expect(User.count).to eq(0)
    end

    it 'shows error for password confirmation mismatch' do
      visit new_user_registration_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'different_password'

      click_button 'Sign up'

      expect(page).to have_content("Password confirmation doesn't match Password")
      expect(User.count).to eq(0)
    end

    it 'shows error for duplicate email' do
      create(:user, email: 'existing@example.com')

      visit new_user_registration_path

      fill_in 'Email', with: 'existing@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'

      click_button 'Sign up'

      expect(page).to have_content('Email has already been taken')
      expect(User.count).to eq(1)
    end
  end

  describe 'form navigation' do
    it 'provides link to sign in page' do
      visit new_user_registration_path

      expect(page).to have_link('Log in', href: new_user_session_path)
    end

    it 'provides link to forgot password' do
      visit new_user_registration_path

      expect(page).to have_link('Forgot your password?', href: new_user_password_path)
    end
  end
end
