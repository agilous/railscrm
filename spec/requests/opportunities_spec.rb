require 'rails_helper'

RSpec.describe 'Opportunities', type: :request do
  let(:user) { create(:approved_user) }
  let(:opportunity) { create(:opportunity) }

  before do
    sign_in user
  end


  describe 'POST /opportunities' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          opportunity: {
            opportunity_name: 'Test Opportunity',
            account_name: 'Test Account',
            owner: user.email,
            amount: 10000,
            closing_date: Date.tomorrow,
            stage: 'prospecting',
            type: 'new_customer'
          }
        }
      end

      it 'creates a new opportunity' do
        expect {
          post opportunities_path, params: valid_attributes
        }.to change(Opportunity, :count).by(1)
      end

      it 'redirects to the opportunity' do
        post opportunities_path, params: valid_attributes
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe 'PATCH /opportunities/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        { opportunity: { opportunity_name: 'Updated Opportunity Name' } }
      end

      it 'updates the opportunity' do
        patch opportunity_path(opportunity), params: new_attributes
        opportunity.reload
        expect(opportunity.opportunity_name).to eq('Updated Opportunity Name')
      end

      it 'redirects to the opportunity' do
        patch opportunity_path(opportunity), params: new_attributes
        expect(response).to redirect_to(opportunity_path(opportunity))
      end
    end
  end

  describe 'DELETE /opportunities/:id' do
    let!(:opportunity_to_delete) { create(:opportunity) }

    it 'destroys the opportunity' do
      expect {
        delete opportunity_path(opportunity_to_delete)
      }.to change(Opportunity, :count).by(-1)
    end

    it 'redirects back' do
      delete opportunity_path(opportunity_to_delete)
      expect(response).to have_http_status(:found)
    end
  end
end
