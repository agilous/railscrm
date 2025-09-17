require 'rails_helper'

RSpec.describe 'Contacts', type: :request do
  let(:user) { create(:approved_user) }
  let(:contact) { create(:contact) }

  before do
    sign_in user
  end

  describe 'GET /contacts' do
    let!(:contact1) { create(:contact, first_name: 'Alice', last_name: 'Johnson', company: 'Design Co', email: 'alice@example.com') }
    let!(:contact2) { create(:contact, first_name: 'Bob', last_name: 'Wilson', company: 'Dev Corp', email: 'bob@example.com') }
    let!(:contact3) { create(:contact, first_name: 'Charlie', last_name: 'Brown', company: 'Tech Inc', email: 'charlie@example.com') }

    it 'returns a successful response' do
      get contacts_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the contacts index template' do
      get contacts_path
      expect(response).to render_template("contacts/index")
    end

    it 'displays all contacts by default' do
      get contacts_path
      expect(response.body).to include('Alice Johnson')
      expect(response.body).to include('Bob Wilson')
      expect(response.body).to include('Charlie Brown')
    end

    describe 'filtering' do
      it 'filters by name' do
        get contacts_path, params: { name: 'Alice' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).not_to include('Bob Wilson')
        expect(response.body).not_to include('Charlie Brown')
      end

      it 'filters by company' do
        get contacts_path, params: { company: 'Design' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).not_to include('Bob Wilson')
        expect(response.body).not_to include('Charlie Brown')
      end

      it 'filters by email' do
        get contacts_path, params: { email: 'alice@' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).not_to include('Bob Wilson')
        expect(response.body).not_to include('Charlie Brown')
      end

      it 'filters by created_since date' do
        old_contact = create(:contact, first_name: 'Old', last_name: 'Contact', created_at: 1.month.ago)

        get contacts_path, params: { created_since: 1.week.ago.to_date }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).not_to include('Old Contact')
      end

      it 'filters by created_before date' do
        new_contact = create(:contact, first_name: 'New', last_name: 'Contact', created_at: 1.day.ago)

        get contacts_path, params: { created_before: 1.week.ago.to_date }

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('New Contact')
      end

      it 'applies multiple filters' do
        get contacts_path, params: { name: 'Alice', company: 'Design' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).not_to include('Bob Wilson')
      end

      it 'shows filter count badge when filters are active' do
        get contacts_path, params: { name: 'Alice', company: 'Design' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('2 filters active')
      end

      it 'shows clear filters link when filters are active' do
        get contacts_path, params: { name: 'Alice' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Clear Filters')
      end
    end

    describe 'sorting' do
      it 'sorts by first_name ascending' do
        get contacts_path, params: { sort: 'first_name', direction: 'asc' }

        expect(response).to have_http_status(:success)
        # Alice should appear before Bob in the HTML
        alice_position = response.body.index('Alice Johnson')
        bob_position = response.body.index('Bob Wilson')
        expect(alice_position).to be < bob_position
      end

      it 'sorts by first_name descending' do
        get contacts_path, params: { sort: 'first_name', direction: 'desc' }

        expect(response).to have_http_status(:success)
        # Charlie should appear before Alice in the HTML
        charlie_position = response.body.index('Charlie Brown')
        alice_position = response.body.index('Alice Johnson')
        expect(charlie_position).to be < alice_position
      end

      it 'sorts by company' do
        get contacts_path, params: { sort: 'company', direction: 'asc' }

        expect(response).to have_http_status(:success)
        # Design Co should appear before Dev Corp
        design_position = response.body.index('Design Co')
        dev_position = response.body.index('Dev Corp')
        expect(design_position).to be < dev_position
      end

      it 'sorts by email' do
        get contacts_path, params: { sort: 'email', direction: 'asc' }

        expect(response).to have_http_status(:success)
        # Should be sorted alphabetically by email
        expect(response.body).to match(/alice@example\.com.*bob@example\.com.*charlie@example\.com/m)
      end

      it 'defaults to created_at desc when no sort specified' do
        get contacts_path

        expect(response).to have_http_status(:success)
        # Most recent contacts should appear first (contact3 was created last)
        charlie_position = response.body.index('Charlie Brown')
        alice_position = response.body.index('Alice Johnson')
        expect(charlie_position).to be < alice_position
      end

      it 'validates sort column to prevent SQL injection' do
        get contacts_path, params: { sort: 'malicious_column; DROP TABLE contacts;', direction: 'asc' }

        expect(response).to have_http_status(:success)
        # Should fall back to default sorting without error
      end
    end

    describe 'pagination' do
      before do
        # Create enough contacts to trigger pagination (25 per page)
        30.times do |i|
          create(:contact, first_name: "Contact#{i}", last_name: "User#{i}", email: "contact#{i}@example.com")
        end
      end

      it 'paginates results' do
        get contacts_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing')
        expect(response.body).to include('of')
        expect(response.body).to include('contacts')
      end

      it 'shows correct page when page parameter is provided' do
        get contacts_path, params: { page: 2 }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing')
      end

      it 'preserves filters during pagination' do
        get contacts_path, params: { page: 1, name: 'Contact1' }

        expect(response).to have_http_status(:success)
        # Should maintain the name filter
        expect(response.body).to include('Contact1')
      end
    end
  end

  describe 'GET /contacts/:id' do
    it 'returns a successful response' do
      get contact_path(contact)
      expect(response).to have_http_status(:success)
    end

    it 'renders the show contact template' do
      get contact_path(contact)
      expect(response).to render_template("contacts/show")
    end

    it 'displays contact information' do
      contact = create(:contact, first_name: 'John', last_name: 'Doe', email: 'john@example.com', phone: '555-1234')
      get contact_path(contact)

      expect(response.body).to include('John Doe')
      expect(response.body).to include('john@example.com')
      expect(response.body).to include('555-1234')
    end

    it 'shows edit and delete buttons' do
      get contact_path(contact)

      expect(response.body).to include('Edit')
      expect(response.body).to include('Delete')
    end
  end

  describe 'GET /contacts/new' do
    it 'returns a successful response' do
      get new_contact_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the new contact template' do
      get new_contact_path
      expect(response).to render_template("contacts/new")
    end

    it 'displays the form fields' do
      get new_contact_path

      expect(response.body).to include('Create New Contact')
      expect(response.body).to include('Personal Information')
      expect(response.body).to include('Address Information')
    end
  end

  describe 'GET /contacts/:id/edit' do
    it 'returns a successful response' do
      get edit_contact_path(contact)
      expect(response).to have_http_status(:success)
    end

    it 'renders the edit contact template' do
      get edit_contact_path(contact)
      expect(response).to render_template("contacts/edit")
    end

    it 'displays the form with current values' do
      contact = create(:contact, first_name: 'John', last_name: 'Doe')
      get edit_contact_path(contact)

      expect(response.body).to include('Edit Contact: John Doe')
      expect(response.body).to include('value="John"')
      expect(response.body).to include('value="Doe"')
    end
  end

  describe 'POST /contacts' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          contact: {
            first_name: 'John',
            last_name: 'Doe',
            company: 'Test Company',
            email: 'john@example.com',
            phone: '555-1212',
            address: '123 Test St',
            city: 'Test City',
            state: 'TS',
            zip: '12345'
          }
        }
      end

      it 'creates a new contact' do
        expect {
          post contacts_path, params: valid_attributes
        }.to change(Contact, :count).by(1)
      end

      it 'redirects to contacts index' do
        post contacts_path, params: valid_attributes
        expect(response).to redirect_to(contacts_path)
      end

      it 'sets a success flash message' do
        post contacts_path, params: valid_attributes
        follow_redirect!
        expect(response.body).to include('New Contact Created')
      end

      it 'creates contact with all provided attributes' do
        post contacts_path, params: valid_attributes

        contact = Contact.last
        expect(contact.first_name).to eq('John')
        expect(contact.last_name).to eq('Doe')
        expect(contact.company).to eq('Test Company')
        expect(contact.email).to eq('john@example.com')
        expect(contact.phone).to eq('555-1212')
        expect(contact.address).to eq('123 Test St')
        expect(contact.city).to eq('Test City')
        expect(contact.state).to eq('TS')
        expect(contact.zip).to eq('12345')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          contact: {
            first_name: '',  # Required field empty
            last_name: 'Doe',
            email: 'invalid-email',  # Invalid format
            company: 'Test Company'
          }
        }
      end

      it 'does not create a new contact' do
        expect {
          post contacts_path, params: invalid_attributes
        }.not_to change(Contact, :count)
      end

      it 'renders the new template with errors' do
        post contacts_path, params: invalid_attributes
        expect(response).to render_template("contacts/new")
        expect(response.body).to include("Please fix the following errors")
      end

      it 'returns unprocessable entity status' do
        post contacts_path, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with duplicate email' do
      let!(:existing_contact) { create(:contact, email: 'existing@example.com') }
      let(:duplicate_email_attributes) do
        {
          contact: {
            first_name: 'John',
            last_name: 'Doe',
            email: 'existing@example.com'
          }
        }
      end

      it 'does not create a new contact' do
        expect {
          post contacts_path, params: duplicate_email_attributes
        }.not_to change(Contact, :count)
      end

      it 'shows email uniqueness error' do
        post contacts_path, params: duplicate_email_attributes
        expect(response.body).to include('Email has already been taken')
      end
    end
  end

  describe 'PATCH /contacts/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        {
          contact: {
            first_name: 'Updated Name',
            company: 'Updated Company',
            phone: '555-9999'
          }
        }
      end

      it 'updates the contact' do
        patch contact_path(contact), params: new_attributes
        contact.reload
        expect(contact.first_name).to eq('Updated Name')
        expect(contact.company).to eq('Updated Company')
        expect(contact.phone).to eq('555-9999')
      end

      it 'redirects to the contact' do
        patch contact_path(contact), params: new_attributes
        expect(response).to redirect_to(contact_path(contact))
      end

      it 'sets a success flash message' do
        patch contact_path(contact), params: new_attributes
        follow_redirect!
        expect(response.body).to include('Contact Updated')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        { contact: { first_name: '', email: 'invalid-email' } }
      end

      it 'does not update the contact' do
        original_name = contact.first_name
        patch contact_path(contact), params: invalid_attributes
        contact.reload
        expect(contact.first_name).to eq(original_name)
      end

      it 'renders the edit template with errors' do
        patch contact_path(contact), params: invalid_attributes
        expect(response).to render_template("contacts/edit")
        expect(response.body).to include("Please fix the following errors")
      end
    end
  end

  describe 'DELETE /contacts/:id' do
    let!(:contact_to_delete) { create(:contact) }

    it 'destroys the contact' do
      expect {
        delete contact_path(contact_to_delete)
      }.to change(Contact, :count).by(-1)
    end

    it 'redirects back or to contacts index' do
      delete contact_path(contact_to_delete)
      expect(response).to have_http_status(:found)
    end

    it 'sets a success flash message' do
      delete contact_path(contact_to_delete)
      follow_redirect!
      expect(response.body).to include('Contact Deleted')
    end

    context 'when trying to delete current user contact' do
      it 'deletes the contact anyway since Contact != User' do
        user_contact = create(:contact, email: user.email)

        expect {
          delete contact_path(user_contact)
        }.to change(Contact, :count).by(-1)
      end
    end
  end

  describe 'authentication' do
    before do
      sign_out user
    end

    it 'redirects to login for index' do
      get contacts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for show' do
      get contact_path(contact)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for new' do
      get new_contact_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for create' do
      post contacts_path, params: { contact: { first_name: 'Test' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for edit' do
      get edit_contact_path(contact)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for update' do
      patch contact_path(contact), params: { contact: { first_name: 'Test' } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for delete' do
      delete contact_path(contact)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
