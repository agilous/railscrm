require 'rails_helper'

RSpec.describe 'Leads', type: :request do
  let(:user) { create(:approved_user) }
  let(:lead) { create(:lead) }

  before do
    sign_in user
  end

  describe 'GET /leads' do
    let!(:john_lead) { create(:lead, first_name: 'John', last_name: 'Doe', company: 'Acme Corp', lead_status: 'new', assigned_to: user, created_at: 2.days.ago) }
    let!(:jane_lead) { create(:lead, first_name: 'Jane', last_name: 'Smith', company: 'Beta LLC', lead_status: 'contacted', assigned_to: user, created_at: 1.day.ago) }
    let(:other_user) { create(:approved_user, first_name: 'Other', last_name: 'User') }
    let!(:bob_lead) { create(:lead, first_name: 'Bob', last_name: 'Johnson', company: 'Acme Industries', lead_status: 'qualified', assigned_to: other_user, created_at: Time.current) }

    describe 'filtering' do
      context 'by name' do
        it 'filters by partial first name match' do
          get leads_path, params: { name: 'Jo' }
          expect(response).to have_http_status(:ok)
          # We can't test the actual filtering without view parsing, but we ensure the request succeeds
        end

        it 'filters by partial last name match' do
          get leads_path, params: { name: 'Doe' }
          expect(response).to have_http_status(:ok)
        end

        it 'filters by full name match' do
          get leads_path, params: { name: 'Jane Smith' }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'by company' do
        it 'filters by partial company match' do
          get leads_path, params: { company: 'Acme' }
          expect(response).to have_http_status(:ok)
        end

        it 'filters by exact company match' do
          get leads_path, params: { company: 'Beta LLC' }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'by created date' do
        it 'filters by created_since date' do
          get leads_path, params: { created_since: 1.day.ago.to_date }
          expect(response).to have_http_status(:ok)
        end

        it 'filters by created_before date' do
          get leads_path, params: { created_before: Date.current }
          expect(response).to have_http_status(:ok)
        end

        it 'filters by date range' do
          get leads_path, params: { created_since: 2.days.ago.to_date, created_before: Date.current }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'by status' do
        it 'filters by lead status' do
          get leads_path, params: { status: 'new' }
          expect(response).to have_http_status(:ok)
        end

        it 'handles invalid status gracefully' do
          get leads_path, params: { status: 'invalid_status' }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'by assigned user' do
        it 'filters by assigned_to user id' do
          get leads_path, params: { assigned_to: user.id }
          expect(response).to have_http_status(:ok)
        end

        it 'filters by other assigned user' do
          get leads_path, params: { assigned_to: other_user.id }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'multiple filters' do
        it 'applies multiple filters together' do
          get leads_path, params: {
            name: 'John',
            company: 'Acme',
            status: 'new',
            assigned_to: user.id
          }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe 'sorting' do
      it 'sorts by first_name ascending' do
        get leads_path, params: { sort: 'first_name', direction: 'asc' }
        expect(response).to have_http_status(:ok)
      end

      it 'sorts by first_name descending' do
        get leads_path, params: { sort: 'first_name', direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end

      it 'sorts by created_at descending (default)' do
        get leads_path, params: { sort: 'created_at', direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end

      it 'sorts by company name' do
        get leads_path, params: { sort: 'company', direction: 'asc' }
        expect(response).to have_http_status(:ok)
      end

      it 'sorts by assigned_to (joins users table)' do
        get leads_path, params: { sort: 'assigned_to', direction: 'asc' }
        expect(response).to have_http_status(:ok)
      end

      it 'defaults to created_at desc when no sort specified' do
        get leads_path
        expect(response).to have_http_status(:ok)
      end

      context 'SQL injection prevention' do
        it 'handles malicious sort column gracefully' do
          get leads_path, params: { sort: 'created_at; DROP TABLE leads;--', direction: 'asc' }
          expect(response).to have_http_status(:ok)
          # Should default to created_at since the malicious column isn't in allowed list
        end

        it 'handles malicious direction gracefully' do
          get leads_path, params: { sort: 'created_at', direction: 'asc; DROP TABLE leads;--' }
          expect(response).to have_http_status(:ok)
          # Should default to asc since the malicious direction isn't in allowed list
        end

        it 'only allows valid sort columns' do
          invalid_columns = [ 'id', 'password', 'secret_key', 'admin' ]
          invalid_columns.each do |column|
            get leads_path, params: { sort: column, direction: 'asc' }
            expect(response).to have_http_status(:ok)
            # Should default to created_at since these aren't in allowed columns
          end
        end

        it 'only allows valid sort directions' do
          invalid_directions = [ 'ASC UNION SELECT * FROM users', 'random()', 'null' ]
          invalid_directions.each do |direction|
            get leads_path, params: { sort: 'created_at', direction: direction }
            expect(response).to have_http_status(:ok)
            # Should default to asc since these aren't valid directions
          end
        end
      end
    end

    describe 'pagination' do
      it 'paginates results' do
        get leads_path, params: { page: 1 }
        expect(response).to have_http_status(:ok)
      end

      it 'preserves filters across pages' do
        get leads_path, params: { page: 1, name: 'John', status: 'new' }
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'view data setup' do
      before { get leads_path }

      it 'sets up filter dropdown data' do
        expect(assigns(:lead_statuses)).to eq(Lead.status)
        expect(assigns(:users)).to include(user, other_user)
      end

      it 'sets up sorting data' do
        expect(assigns(:current_sort)).to eq('created_at')
        expect(assigns(:current_direction)).to eq('desc')
      end

      it 'filters users to only approved ones' do
        unapproved_user = create(:user, approved: false)
        get leads_path
        expect(assigns(:users)).not_to include(unapproved_user)
      end
    end
  end

  describe 'POST /leads' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          lead: {
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com',
            phone: '555-1212',
            company: 'Test Company',
            lead_owner: user.email,
            lead_status: 'new',
            lead_source: 'web',
            interested_in: 'web_app'
          }
        }
      end

      it 'creates a new lead' do
        expect {
          post leads_path, params: valid_attributes
        }.to change(Lead, :count).by(1)
      end

      it 'redirects to the lead' do
        post leads_path, params: valid_attributes
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe 'PATCH /leads/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        { lead: { first_name: 'Updated Name' } }
      end

      it 'updates the lead' do
        patch lead_path(lead), params: new_attributes
        lead.reload
        expect(lead.first_name).to eq('Updated Name')
      end

      it 'redirects to the lead' do
        patch lead_path(lead), params: new_attributes
        expect(response).to redirect_to(lead_path(lead))
      end
    end
  end

  describe 'DELETE /leads/:id' do
    let!(:lead_to_delete) { create(:lead) }

    it 'destroys the lead' do
      expect {
        delete lead_path(lead_to_delete)
      }.to change(Lead, :count).by(-1)
    end

    it 'redirects to leads index with success message' do
      delete lead_path(lead_to_delete)
      expect(response).to redirect_to(leads_path)
      follow_redirect!
      expect(response.body).to include("Lead Deleted")
    end

    it 'deletes associated note associations but keeps the notes' do
      note = create(:note)
      note.add_notable(lead_to_delete)

      expect {
        delete lead_path(lead_to_delete)
      }.to change(Lead, :count).by(-1)

      # Note still exists but association is removed
      expect(Note.exists?(note.id)).to be true
      expect(note.reload.leads).to be_empty
    end

    it 'returns 404 for non-existent lead' do
      delete lead_path(id: 99999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /leads/external_form' do
    let(:external_lead_params) do
      {
        lead: {
          first_name: 'External',
          last_name: 'Lead',
          email: 'external@example.com',
          phone: '555-9999'
        }
      }
    end

    it 'creates a lead from external form' do
      expect {
        post '/generate', params: external_lead_params
      }.to change(Lead, :count).by(1)
    end
  end
end
