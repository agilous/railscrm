require 'rails_helper'

RSpec.describe 'Activity Scheduling', type: :system, js: true do
  let(:user) { create(:approved_user) }
  let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson', email: 'alice@example.com') }

  before do
    login_as user
  end

  describe 'Scheduling an activity from contact page' do
    context 'with valid data' do
      it 'creates a new activity for the contact' do
        visit contact_path(contact)

        expect(page).to have_button('Schedule Activity')

        expect {
          click_button 'Schedule Activity'

          select 'Call', from: 'activity_activity_type'
          fill_in 'activity_title', with: 'Follow up call'
          fill_in 'activity_description', with: 'Discuss project requirements'
          select 'High', from: 'activity_priority'
          fill_in 'activity_duration', with: '30'

          within '#activityModal' do
            click_button 'Schedule Activity'
          end

          # Wait for the modal to close and verify activity was created
          expect(page).to have_no_css('#activityModal:not(.hidden)', wait: 5)
        }.to change { contact.reload.activities.count }.by(1)

        activity = contact.activities.last
        expect(activity.activity_type).to eq('Call')
        expect(activity.title).to eq('Follow up call')
        expect(activity.description).to eq('Discuss project requirements')
        expect(activity.priority).to eq('High')
        expect(activity.duration).to eq(30)
      end

      it 'allows scheduling without optional fields' do
        visit contact_path(contact)

        click_button 'Schedule Activity'

        select 'Meeting', from: 'activity_activity_type'
        fill_in 'activity_title', with: 'Quick sync'

        within '#activityModal' do
          click_button 'Schedule Activity'
        end

        expect(page).not_to have_css('#activityModal:not(.hidden)')

        activity = contact.activities.last
        expect(activity.activity_type).to eq('Meeting')
        expect(activity.title).to eq('Quick sync')
        expect(activity.description).to be_blank
        expect(activity.priority).to eq('Medium')
      end

      it 'allows assigning activity to a user' do
        assignee = create(:approved_user)
        visit contact_path(contact)

        click_button 'Schedule Activity'

        select 'Demo', from: 'activity_activity_type'
        fill_in 'activity_title', with: 'Product demo'
        select assignee.full_name, from: 'activity_user_id'

        within '#activityModal' do
          click_button 'Schedule Activity'
        end

        expect(page).not_to have_css('#activityModal:not(.hidden)')

        activity = contact.activities.last
        expect(activity.user).to eq(assignee)
      end

      it 'creates activities with different types' do
        Activity::ACTIVITY_TYPES.each do |type|
          visit contact_path(contact)
          click_button 'Schedule Activity'

          select type, from: 'activity_activity_type'
          fill_in 'activity_title', with: "Test #{type}"

          within '#activityModal' do
            click_button 'Schedule Activity'
          end

          expect(page).not_to have_css('#activityModal:not(.hidden)')

          activity = contact.activities.last
          expect(activity.activity_type).to eq(type)
          expect(activity.title).to eq("Test #{type}")
        end
      end

      it 'creates activities with different priorities' do
        Activity::PRIORITY_LEVELS.each do |priority|
          visit contact_path(contact)
          click_button 'Schedule Activity'

          select 'Call', from: 'activity_activity_type'
          fill_in 'activity_title', with: "#{priority} priority call"
          select priority, from: 'activity_priority'

          within '#activityModal' do
            click_button 'Schedule Activity'
          end

          expect(page).not_to have_css('#activityModal:not(.hidden)')

          activity = contact.activities.last
          expect(activity.priority).to eq(priority)
        end
      end

      it 'handles form submission and shows appropriate feedback', js: true do
        visit contact_path(contact)

        # Open the modal
        click_button 'Schedule Activity'
        expect(page).to have_css('#activityModal:not(.hidden)')

        # Submit with missing required fields
        within '#activityModal' do
          # Leave required fields empty to potentially trigger validation
          click_button 'Schedule Activity'
        end

        # Wait for form processing (may redirect or show errors)
        sleep(1)

        # The key test: no 500 error should occur due to missing template
        expect(page).not_to have_content('Missing template')
        expect(page).not_to have_content('ActionView::MissingTemplate')

        # The form should either show errors or redirect - both are acceptable
        # as long as no crash occurs
      end

      it 'does not crash on validation errors with turbo_stream', js: true do
        visit contact_path(contact)

        # Open modal
        click_button 'Schedule Activity'

        # Submit form with some but not all data
        within '#activityModal' do
          fill_in 'activity_title', with: 'Test Title'
          # Leave activity_type empty which is required
          click_button 'Schedule Activity'
        end

        # Wait for any turbo_stream response processing
        sleep(1)

        # Main test: page should not crash with missing template error
        expect(page).not_to have_content('Missing template')
        expect(page).not_to have_content('Internal Server Error')
        expect(page).not_to have_content('ActionView::MissingTemplate')

        # Should be on a valid page (either contact page or modal still open)
        expect(page).to have_content(contact.full_name).or(have_css('#activityModal'))
      end
    end

    context 'with invalid data' do
      it 'requires activity_type' do
        expect {
          post contact_activities_path(contact), params: {
            activity: {
              title: 'Missing type'
            }
          }
        }.not_to change(Activity, :count)
      end

      it 'requires title' do
        expect {
          post contact_activities_path(contact), params: {
            activity: {
              activity_type: 'Call'
            }
          }
        }.not_to change(Activity, :count)
      end

      it 'rejects invalid activity_type' do
        expect {
          post contact_activities_path(contact), params: {
            activity: {
              activity_type: 'InvalidType',
              title: 'Test'
            }
          }
        }.not_to change(Activity, :count)
      end

      it 'rejects invalid priority' do
        expect {
          post contact_activities_path(contact), params: {
            activity: {
              activity_type: 'Call',
              title: 'Test',
              priority: 'Urgent'
            }
          }
        }.not_to change(Activity, :count)
      end
    end
  end

  describe 'Viewing activities on contact page' do
    let!(:call_activity) do
      create(:activity,
        contact: contact,
        activity_type: 'Call',
        title: 'Follow up call',
        description: 'Discuss requirements',
        completed_at: nil,
        due_date: 1.day.from_now
      )
    end

    let!(:completed_activity) do
      create(:activity,
        contact: contact,
        activity_type: 'Meeting',
        title: 'Initial meeting',
        completed_at: 1.day.ago
      )
    end

    let!(:overdue_activity) do
      create(:activity,
        contact: contact,
        activity_type: 'Demo',
        title: 'Overdue demo',
        completed_at: nil,
        due_date: 2.days.ago
      )
    end

    it 'displays activities in the contact timeline' do
      visit contact_path(contact)

      expect(page).to have_content('Follow up call')
      expect(page).to have_content('Initial meeting')
      expect(page).to have_content('Overdue demo')
    end

    it 'shows activity types' do
      visit contact_path(contact)

      expect(page).to have_content('Call')
      expect(page).to have_content('Meeting')
      expect(page).to have_content('Demo')
    end

    it 'displays completed status for finished activities' do
      visit contact_path(contact)

      # Completed activity should show as "Done" or "Completed"
      expect(page).to have_content('Done').or have_content('Completed')
    end

    it 'displays overdue status for past-due activities' do
      visit contact_path(contact)

      # Overdue activity should show as "Overdue" or "Late"
      expect(page).to have_content('Overdue').or have_content('Late')
    end

    it 'shows activity count in activities tab' do
      visit contact_path(contact)

      # Should show count of activities (3 in this case)
      expect(page).to have_content('Activities (3)').or have_content('Activities(3)')
    end
  end

  describe 'Updating activities' do
    let!(:activity) do
      create(:activity,
        contact: contact,
        activity_type: 'Call',
        title: 'Original title',
        priority: 'Low'
      )
    end

    it 'allows updating activity details' do
      patch contact_activity_path(contact, activity), params: {
        activity: {
          title: 'Updated title',
          priority: 'High',
          description: 'New description'
        }
      }

      activity.reload
      expect(activity.title).to eq('Updated title')
      expect(activity.priority).to eq('High')
      expect(activity.description).to eq('New description')
    end

    it 'preserves activity_type and contact association' do
      original_type = activity.activity_type
      original_contact = activity.contact

      patch contact_activity_path(contact, activity), params: {
        activity: {
          title: 'Updated title'
        }
      }

      activity.reload
      expect(activity.activity_type).to eq(original_type)
      expect(activity.contact).to eq(original_contact)
    end
  end

  describe 'Completing activities' do
    let!(:pending_activity) do
      create(:activity,
        contact: contact,
        activity_type: 'Call',
        title: 'Pending call',
        completed_at: nil,
        due_date: 1.day.from_now
      )
    end

    it 'marks activity as completed' do
      expect(pending_activity.completed?).to be false

      patch complete_contact_activity_path(contact, pending_activity)

      pending_activity.reload
      expect(pending_activity.completed?).to be true
      expect(pending_activity.completed_at).to be_present
    end

    it 'changes activity status from Scheduled to Completed' do
      expect(pending_activity.status).to eq('Scheduled')

      patch complete_contact_activity_path(contact, pending_activity)

      pending_activity.reload
      expect(pending_activity.status).to eq('Completed')
    end

    it 'changes status color from blue to green' do
      expect(pending_activity.status_color).to eq('blue')

      patch complete_contact_activity_path(contact, pending_activity)

      pending_activity.reload
      expect(pending_activity.status_color).to eq('green')
    end
  end

  describe 'Deleting activities' do
    let!(:activity_to_delete) do
      create(:activity,
        contact: contact,
        activity_type: 'Call',
        title: 'Activity to delete'
      )
    end

    it 'removes the activity' do
      expect(contact.activities).to include(activity_to_delete)

      delete contact_activity_path(contact, activity_to_delete)

      expect(contact.activities.reload).not_to include(activity_to_delete)
      expect(Activity.exists?(activity_to_delete.id)).to be false
    end

    it 'decreases activity count' do
      initial_count = contact.activities.count

      delete contact_activity_path(contact, activity_to_delete)

      expect(contact.activities.count).to eq(initial_count - 1)
    end
  end

  describe 'Activity associations with users' do
    let(:assignee) { create(:approved_user, first_name: 'Bob', last_name: 'Smith') }
    let!(:assigned_activity) do
      create(:activity,
        contact: contact,
        user: assignee,
        activity_type: 'Meeting',
        title: 'Team meeting'
      )
    end

    it 'associates activity with assigned user' do
      expect(assigned_activity.user).to eq(assignee)
      expect(assignee.activities).to include(assigned_activity)
    end

    it 'allows activities without assigned user' do
      unassigned = create(:activity,
        contact: contact,
        activity_type: 'Call',
        title: 'Unassigned call',
        user: nil
      )

      expect(unassigned.user).to be_nil
      expect(unassigned).to be_valid
    end
  end

  describe 'Activity status helpers' do
    it 'correctly identifies completed activities' do
      completed = create(:activity, contact: contact, completed_at: Time.current)
      pending = create(:activity, contact: contact, completed_at: nil)

      expect(completed.completed?).to be true
      expect(pending.completed?).to be false
    end

    it 'correctly identifies overdue activities' do
      overdue = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago)
      upcoming = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now)
      no_date = create(:activity, contact: contact, completed_at: nil, due_date: nil)

      expect(overdue.overdue?).to be true
      expect(upcoming.overdue?).to be false
      expect(no_date.overdue?).to be false
    end

    it 'returns correct status strings' do
      completed = create(:activity, contact: contact, completed_at: Time.current)
      overdue = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago)
      scheduled = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now)

      expect(completed.status).to eq('Completed')
      expect(overdue.status).to eq('Overdue')
      expect(scheduled.status).to eq('Scheduled')
    end

    it 'returns correct status colors' do
      completed = create(:activity, contact: contact, completed_at: Time.current)
      overdue = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago)
      scheduled = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now)

      expect(completed.status_color).to eq('green')
      expect(overdue.status_color).to eq('red')
      expect(scheduled.status_color).to eq('blue')
    end
  end

  describe 'Activity scopes' do
    let!(:completed1) { create(:activity, contact: contact, completed_at: 1.day.ago) }
    let!(:completed2) { create(:activity, contact: contact, completed_at: 2.days.ago) }
    let!(:pending1) { create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now) }
    let!(:pending2) { create(:activity, contact: contact, completed_at: nil, due_date: 2.days.from_now) }
    let!(:overdue) { create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago) }

    it 'filters completed activities' do
      expect(contact.activities.completed).to match_array([ completed1, completed2 ])
    end

    it 'filters pending activities' do
      expect(contact.activities.pending).to match_array([ pending1, pending2, overdue ])
    end

    it 'filters upcoming activities' do
      expect(contact.activities.upcoming).to match_array([ pending1, pending2 ])
    end

    it 'filters overdue activities' do
      expect(contact.activities.overdue).to eq([ overdue ])
    end

    it 'orders activities by recent first' do
      activities = contact.activities.recent.to_a
      expect(activities.first.created_at).to be >= activities.last.created_at
    end
  end
end
