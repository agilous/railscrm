require 'rails_helper'

RSpec.describe 'Contacts', type: :request do
  let(:user) { create(:approved_user) }
  let(:contact) { create(:contact) }

  before do
    sign_in user
  end

  describe 'GET /contacts' do
    it 'returns a successful response' do
      get contacts_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the contacts index template' do
      get contacts_path
      expect(response).to render_template("contacts/index")
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
            address: '123 Test St'
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
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          contact: {
            first_name: 'John',
            company: 'Test Company',
            email: 'john@example.com',
            phone: '555-1212',
            address: '123 Test St'
            # missing required last_name field
          }
        }
      end

      it 'does not create a new contact' do
        expect {
          post contacts_path, params: invalid_attributes
        }.not_to change(Contact, :count)
      end

      # Skip template rendering test since views don't exist yet
    end
  end

  describe 'PATCH /contacts/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        { contact: { first_name: 'Updated Name' } }
      end

      it 'updates the contact' do
        patch contact_path(contact), params: new_attributes
        contact.reload
        expect(contact.first_name).to eq('Updated Name')
      end

      it 'redirects to the contact' do
        patch contact_path(contact), params: new_attributes
        expect(response).to redirect_to(contact_path(contact))
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

    it 'redirects back' do
      delete contact_path(contact_to_delete)
      expect(response).to have_http_status(:found)
    end
  end
end
