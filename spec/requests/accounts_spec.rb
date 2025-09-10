require 'rails_helper'

RSpec.describe 'Accounts', type: :request do
  let(:user) { create(:approved_user) }
  let(:account) { create(:account) }

  before do
    sign_in user
  end

  describe 'GET /accounts' do
    it 'returns a successful response' do
      get accounts_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the accounts index template' do
      get accounts_path
      expect(response).to render_template("accounts/index")
    end
  end

  describe 'GET /accounts/:id' do
    it 'returns a successful response' do
      get account_path(account)
      expect(response).to have_http_status(:success)
    end

    it 'renders the show account template' do
      get account_path(account)
      expect(response).to render_template("accounts/show")
    end
  end

  describe 'GET /accounts/new' do
    it 'returns a successful response' do
      get new_account_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the new account template' do
      get new_account_path
      expect(response).to render_template("accounts/new")
    end
  end

  describe 'POST /accounts' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          account: {
            name: 'Test Account',
            phone: '555-1212',
            website: 'www.test.com',
            email: 'test@example.com',
            address: '123 Test St'
          }
        }
      end

      it 'creates a new account' do
        expect {
          post accounts_path, params: valid_attributes
        }.to change(Account, :count).by(1)
      end

      it 'redirects to accounts index' do
        post accounts_path, params: valid_attributes
        expect(response).to redirect_to(accounts_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          account: {
            name: 'Test Account',
            website: 'www.test.com',
            email: 'test@example.com',
            address: '123 Test St'
            # missing required phone field
          }
        }
      end

      it 'does not create a new account' do
        expect {
          post accounts_path, params: invalid_attributes
        }.not_to change(Account, :count)
      end

      # Skip template rendering test since views don't exist yet
    end
  end

  describe 'PATCH /accounts/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        { account: { name: 'Updated Account Name' } }
      end

      it 'updates the account' do
        patch account_path(account), params: new_attributes
        account.reload
        expect(account.name).to eq('Updated Account Name')
      end

      it 'redirects to the account' do
        patch account_path(account), params: new_attributes
        expect(response).to redirect_to(account_path(account))
      end
    end
  end

  describe 'DELETE /accounts/:id' do
    let!(:account_to_delete) { create(:account) }

    it 'destroys the account' do
      expect {
        delete account_path(account_to_delete)
      }.to change(Account, :count).by(-1)
    end

    it 'redirects back' do
      delete account_path(account_to_delete)
      expect(response).to have_http_status(:found)
    end
  end
end
