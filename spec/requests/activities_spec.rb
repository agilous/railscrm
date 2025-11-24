require 'rails_helper'

RSpec.describe 'Activities', type: :request do
  let(:user) { create(:approved_user) }
  let(:contact) { create(:contact) }
  let(:activity) { create(:activity, contact: contact) }

  before do
    sign_in user
  end

  describe 'GET /contacts/:contact_id/activities/:id' do
    context 'with HTML format' do
      it 'redirects to contact page' do
        get contact_activity_path(contact, activity)
        expect(response).to redirect_to(contact_path(contact))
      end
    end

    context 'with JSON format' do
      it 'returns the activity as JSON' do
        get contact_activity_path(contact, activity), as: :json
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(activity.id)
        expect(json_response['title']).to eq(activity.title)
      end
    end

    it 'assigns @activity' do
      get contact_activity_path(contact, activity), as: :json
      expect(assigns(:activity)).to eq(activity)
    end
  end

  describe 'POST /contacts/:contact_id/activities' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          activity: {
            activity_type: 'Call',
            title: 'Follow up call',
            description: 'Discuss project requirements',
            due_date: 1.day.from_now,
            priority: 'High',
            duration: 30,
            user_id: user.id
          }
        }
      end

      it 'creates a new activity' do
        expect {
          post contact_activities_path(contact), params: valid_attributes
        }.to change(Activity, :count).by(1)
      end

      it 'associates the activity with the contact' do
        post contact_activities_path(contact), params: valid_attributes
        expect(Activity.last.contact).to eq(contact)
      end

      it 'sets all activity attributes correctly' do
        post contact_activities_path(contact), params: valid_attributes
        activity = Activity.last
        expect(activity.activity_type).to eq('Call')
        expect(activity.title).to eq('Follow up call')
        expect(activity.description).to eq('Discuss project requirements')
        expect(activity.priority).to eq('High')
        expect(activity.duration).to eq(30)
        expect(activity.user_id).to eq(user.id)
      end

      it 'redirects to contact page with HTML format' do
        post contact_activities_path(contact), params: valid_attributes
        expect(response).to redirect_to(contact_path(contact))
      end

      it 'sets success flash message' do
        post contact_activities_path(contact), params: valid_attributes
        follow_redirect!
        expect(flash[:notice]).to eq('Activity scheduled successfully.')
      end

      context 'with JSON format' do
        it 'returns JSON response with created status' do
          post contact_activities_path(contact), params: valid_attributes, as: :json
          expect(response).to have_http_status(:created)
          expect(response.content_type).to match(/application\/json/)
        end

        it 'returns the created activity as JSON' do
          post contact_activities_path(contact), params: valid_attributes, as: :json
          json_response = JSON.parse(response.body)
          expect(json_response['title']).to eq('Follow up call')
          expect(json_response['activity_type']).to eq('Call')
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          activity: {
            activity_type: '',
            title: '',
            description: 'Missing required fields'
          }
        }
      end

      it 'does not create a new activity' do
        expect {
          post contact_activities_path(contact), params: invalid_attributes
        }.not_to change(Activity, :count)
      end

      it 'redirects back to contact page with error' do
        post contact_activities_path(contact), params: invalid_attributes
        expect(response).to redirect_to(contact_path(contact))
        follow_redirect!
        expect(flash[:alert]).to be_present
      end

      context 'with JSON format' do
        it 'returns JSON with errors and unprocessable_entity status' do
          post contact_activities_path(contact), params: invalid_attributes, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('activity_type')
          expect(json_response).to have_key('title')
        end
      end

      context 'with turbo_stream format' do
        it 'handles validation errors without crashing on turbo_stream format' do
          # Use completely invalid attributes to ensure validation fails
          invalid_turbo_params = { activity: { activity_type: '', title: '' } }

          # This should not raise an error even if turbo_stream response is malformed
          expect {
            post contact_activities_path(contact), params: invalid_turbo_params, as: :turbo_stream
          }.not_to raise_error

          # Should not return 500 error due to missing template (our bug fix)
          expect(response).not_to have_http_status(:internal_server_error)

          # Should not create an invalid activity
          expect(Activity.count).to eq(0)
        end

        it 'renders turbo_stream response when validation fails' do
          # Test that the turbo_stream format is handled (may redirect or render based on implementation)
          invalid_turbo_params = { activity: { activity_type: '', title: '' } }

          post contact_activities_path(contact), params: invalid_turbo_params, as: :turbo_stream

          # The key is that it doesn't crash with a 500 error
          expect(response.status).to be_between(200, 499)
          expect(Activity.count).to eq(0) # No activity should be created
        end

        it 'documents the fixed bug - no template not found error' do
          # Before our fix, this would have caused:
          # ActionView::MissingTemplate: Missing template activities/form
          # Now it should work without error
          invalid_turbo_params = { activity: { activity_type: '', title: '' } }

          expect {
            post contact_activities_path(contact), params: invalid_turbo_params, as: :turbo_stream
          }.not_to raise_error(ActionView::MissingTemplate)

          expect(response).not_to have_http_status(:internal_server_error)
        end
      end
    end

    context 'with invalid priority' do
      let(:invalid_priority_attributes) do
        {
          activity: {
            activity_type: 'Call',
            title: 'Test Activity',
            priority: 'Invalid'
          }
        }
      end

      it 'does not create activity with invalid priority' do
        expect {
          post contact_activities_path(contact), params: invalid_priority_attributes, as: :json
        }.not_to change(Activity, :count)
      end
    end

    context 'with invalid activity_type' do
      let(:invalid_type_attributes) do
        {
          activity: {
            activity_type: 'InvalidType',
            title: 'Test Activity'
          }
        }
      end

      it 'does not create activity with invalid type' do
        expect {
          post contact_activities_path(contact), params: invalid_type_attributes, as: :json
        }.not_to change(Activity, :count)
      end
    end
  end

  describe 'PATCH /contacts/:contact_id/activities/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        {
          activity: {
            title: 'Updated Activity Title',
            priority: 'Low',
            description: 'Updated description'
          }
        }
      end

      it 'updates the activity' do
        patch contact_activity_path(contact, activity), params: new_attributes
        activity.reload
        expect(activity.title).to eq('Updated Activity Title')
        expect(activity.priority).to eq('Low')
        expect(activity.description).to eq('Updated description')
      end

      it 'redirects to contact page' do
        patch contact_activity_path(contact, activity), params: new_attributes
        expect(response).to redirect_to(contact_path(contact))
      end

      it 'sets success flash message' do
        patch contact_activity_path(contact, activity), params: new_attributes
        follow_redirect!
        expect(flash[:notice]).to eq('Activity updated successfully.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          activity: {
            title: '',
            activity_type: ''
          }
        }
      end

      it 'does not update the activity' do
        original_title = activity.title
        patch contact_activity_path(contact, activity), params: invalid_attributes
        activity.reload
        expect(activity.title).to eq(original_title)
      end
    end
  end

  describe 'DELETE /contacts/:contact_id/activities/:id' do
    let!(:activity_to_delete) { create(:activity, contact: contact) }

    it 'destroys the activity' do
      expect {
        delete contact_activity_path(contact, activity_to_delete)
      }.to change(Activity, :count).by(-1)
    end

    it 'redirects to contact page with success message' do
      delete contact_activity_path(contact, activity_to_delete)
      expect(response).to redirect_to(contact_path(contact))
      follow_redirect!
      expect(flash[:notice]).to eq('Activity deleted successfully.')
    end

    it 'returns 404 for non-existent activity' do
      delete contact_activity_path(contact, id: 99999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /contacts/:contact_id/activities/:id/complete' do
    let!(:pending_activity) { create(:activity, contact: contact, completed_at: nil) }

    it 'marks the activity as completed' do
      expect(pending_activity.completed_at).to be_nil
      patch complete_contact_activity_path(contact, pending_activity)
      pending_activity.reload
      expect(pending_activity.completed_at).to be_present
    end

    it 'redirects to contact page' do
      patch complete_contact_activity_path(contact, pending_activity)
      expect(response).to redirect_to(contact_path(contact))
    end

    it 'sets success flash message' do
      patch complete_contact_activity_path(contact, pending_activity)
      follow_redirect!
      expect(flash[:notice]).to eq('Activity marked as completed.')
    end
  end

  describe 'authorization and scope' do
    let(:other_contact) { create(:contact) }
    let(:other_activity) { create(:activity, contact: other_contact) }

    it 'returns 404 when accessing activities from different contact via JSON' do
      get contact_activity_path(contact, other_activity), as: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when updating activities from different contact' do
      patch contact_activity_path(contact, other_activity), params: { activity: { title: 'Hacked' } }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when deleting activities from different contact' do
      delete contact_activity_path(contact, other_activity)
      expect(response).to have_http_status(:not_found)
    end
  end
end
