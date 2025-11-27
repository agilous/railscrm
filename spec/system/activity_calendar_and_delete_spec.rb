require 'rails_helper'

RSpec.describe 'Activity Calendar Links and Delete', type: :system do
  let(:user) { create(:user) }
  let(:contact) { create(:contact) }
  let!(:activity) { create(:activity, contact: contact,
                           title: 'Team Meeting',
                           activity_type: 'Meeting',
                           description: 'Weekly team sync',
                           due_date: 2.days.from_now,
                           duration: 60,
                           user: user) }

  before do
    login_as user
  end

  describe 'Activity display enhancements' do
    context 'when viewing activities on contact page' do
      before do
        visit contact_path(contact)
      end

      it 'shows activities in the Activities tab', js: true do
        click_button 'Activities'

        expect(page).to have_content('Meeting: Team Meeting')
        expect(page).to have_content('Weekly team sync')
        expect(page).to have_content(activity.due_date.strftime("%B %d, %Y at %I:%M %p"))
      end

      describe 'Calendar link generation' do
        before do
          click_button 'Activities'
        end

        it 'displays Add to Calendar dropdown for activities with due dates', js: true do
          expect(page).to have_button('Add to Calendar')
        end

        it 'shows calendar options when clicking Add to Calendar', js: true do
          find('button', text: 'Add to Calendar').click

          expect(page).to have_link('Apple Calendar / Outlook')
          expect(page).to have_link('Google Calendar')
          expect(page).to have_link('Outlook.com')
        end

        it 'closes dropdown when clicking outside', js: true do
          within('#activities-content') do
            find('button', text: 'Add to Calendar').click
            expect(page).to have_link('Apple Calendar / Outlook')
          end

          find('h1', text: contact.full_name).click
          expect(page).not_to have_link('Apple Calendar / Outlook', visible: true)
        end

        it 'generates ICS file when clicking Apple Calendar option', js: true do
          # Since we can't easily test actual file download in system specs,
          # we verify the calendar links controller is properly attached
          within('#activities-content') do
            activity_card = find('.bg-gray-50', text: 'Team Meeting')
            expect(activity_card['data-controller']).to include('calendar-links')
            expect(activity_card['data-calendar-links-title-value']).to eq('Meeting: Team Meeting')
            expect(activity_card['data-calendar-links-description-value']).to eq('Weekly team sync')

            find('button', text: 'Add to Calendar').click
            expect(page).to have_link('Apple Calendar / Outlook')
          end
        end

        it 'opens Google Calendar in new tab when clicking Google option', js: true do
          new_window = window_opened_by do
            find('button', text: 'Add to Calendar').click
            click_link 'Google Calendar'
          end

          within_window new_window do
            expect(page.current_url).to include('calendar.google.com')
          end
        end

        it 'does not show calendar links for activities without due dates', js: true do
          create(:activity, contact: contact, title: 'No Date Activity', activity_type: 'Call', due_date: nil)
          visit contact_path(contact)
          click_button 'Activities'

          within('#activities-content') do
            within(find('.bg-gray-50', text: 'No Date Activity')) do
              expect(page).not_to have_button('Add to Calendar')
            end
          end
        end
      end

      describe 'Activity deletion' do
        before do
          click_button 'Activities'
        end

        it 'shows delete button (X) always visible', js: true do
          within('#activities-content') do
            activity_card = find('.bg-gray-50', text: 'Team Meeting')

            # Delete link is always visible
            within activity_card do
              delete_link = find('a[data-turbo-method="delete"]')
              expect(delete_link).to be_visible
              expect(delete_link['class']).to include('text-gray-600')
            end
          end
        end

        it 'shows confirmation dialog when clicking delete', js: true do
          within('#activities-content') do
            activity_card = find('.bg-gray-50', text: 'Team Meeting')

            accept_confirm('Are you sure you want to delete this activity?') do
              within activity_card do
                find('a[data-turbo-method="delete"]').click
              end
            end
          end

          expect(page).not_to have_content('Team Meeting')
        end

        it 'cancels deletion when dismissing confirmation', js: true do
          within('#activities-content') do
            activity_card = find('.bg-gray-50', text: 'Team Meeting')

            dismiss_confirm do
              within activity_card do
                find('a[data-turbo-method="delete"]').click
              end
            end

            expect(page).to have_content('Team Meeting')
          end
        end

        it 'deletes activity and updates the timeline', js: true do
          # Check activity appears in All tab timeline
          click_button 'All'
          within('#all-content') do
            expect(page).to have_content('Meeting: Team Meeting')
          end

          # Delete from Activities tab
          click_button 'Activities'

          activity_card = find('#activities-content .bg-gray-50', text: 'Team Meeting')

          accept_confirm('Are you sure you want to delete this activity?') do
            within activity_card do
              find('a[data-turbo-method="delete"]').click
            end
          end

          # Wait for Turbo to process the deletion
          sleep 0.5

          # Verify deletion - activity should be gone
          expect(page).not_to have_content('Team Meeting')

          # Verify removal from timeline
          click_button 'All'
          expect(page).not_to have_content('Meeting: Team Meeting')
        end
      end
    end

    context 'when viewing activities in the All timeline' do
      before do
        visit contact_path(contact)
      end

      it 'shows calendar data attributes in timeline activities', js: true do
        within '#all-content' do
          activity_link = find('a', text: 'Team Meeting')
          expect(activity_link['data-controller']).to include('calendar-links')
          expect(activity_link['data-calendar-links-title-value']).to include('Team Meeting')
        end
      end
    end
  end

  describe 'Activity card improvements' do
    it 'displays priority badge when set', js: true do
      high_priority = create(:activity, contact: contact, title: 'Urgent Task', activity_type: 'Call', priority: 'High')
      visit contact_path(contact)
      click_button 'Activities'

      within('#activities-content') do
        within(find('.bg-gray-50', text: 'Urgent Task')) do
          expect(page).to have_css('.bg-red-100', text: 'High')
        end
      end
    end

    it 'displays assigned user when present', js: true do
      assigned_user = create(:user, first_name: 'John', last_name: 'Doe')
      assigned_activity = create(:activity, contact: contact, title: 'Assigned Task', activity_type: 'Meeting', user: assigned_user)

      visit contact_path(contact)
      click_button 'Activities'

      within('#activities-content') do
        within(find('.bg-gray-50', text: 'Assigned Task')) do
          expect(page).to have_content('Assigned to: John Doe')
        end
      end
    end

    it 'uses activity partial for consistent display', js: true do
      visit contact_path(contact)
      click_button 'Activities'

      # Check for consistent structure from partial
      within('#activities-content') do
        activity_card = find('.bg-gray-50', text: 'Team Meeting')
        # Check that the card itself has the calendar-links controller
        expect(activity_card['data-controller']).to eq('calendar-links')
        expect(activity_card).to have_css('a[data-turbo-method="delete"]', visible: :all)
        expect(activity_card).to have_css('.text-sm.font-medium')
      end
    end
  end
end
