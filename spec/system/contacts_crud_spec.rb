require 'rails_helper'

RSpec.describe 'Contacts CRUD', type: :system do
  let(:user) { create(:approved_user) }

  before do
    login_as user
  end

  describe 'Index page' do
    let!(:contact1) { create(:contact, first_name: 'Alice', last_name: 'Johnson', company: 'Design Co', email: 'alice@example.com', phone: '555-0001') }
    let!(:contact2) { create(:contact, first_name: 'Bob', last_name: 'Wilson', company: 'Dev Corp', email: 'bob@example.com', phone: '555-0002') }
    let!(:contact3) { create(:contact, first_name: 'Charlie', last_name: 'Brown', company: 'Tech Inc', email: 'charlie@example.com', phone: '555-0003') }

    it 'displays all contacts' do
      visit contacts_path

      expect(page).to have_content('Contacts')
      expect(page).to have_content('Manage your contact directory')
      expect(page).to have_content('Alice Johnson')
      expect(page).to have_content('Bob Wilson')
      expect(page).to have_content('Charlie Brown')
      expect(page).to have_content('Design Co')
      expect(page).to have_content('Dev Corp')
      expect(page).to have_content('Tech Inc')
    end

    it 'has a create contact button' do
      visit contacts_path

      expect(page).to have_link('Create Contact', href: new_contact_path)
    end

    it 'allows navigation to individual contacts' do
      visit contacts_path

      click_link 'Alice Johnson'
      expect(page).to have_current_path(contact_path(contact1))
    end

    it 'displays contact emails and phones as clickable links' do
      visit contacts_path

      expect(page).to have_link('alice@example.com', href: 'mailto:alice@example.com')
      expect(page).to have_link('555-0001', href: 'tel:555-0001')
    end

    it 'shows hover effects on table rows', js: true do
      visit contacts_path

      # Check that hover class is present in the HTML
      expect(page).to have_css('tr.hover\\:bg-gray-50')
    end

    describe 'filtering functionality' do
      it 'filters contacts by name' do
        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Name', with: 'Alice'
          click_button 'Apply Filters'
        end

        expect(page).to have_content('Alice Johnson')
        expect(page).not_to have_content('Bob Wilson')
        expect(page).not_to have_content('Charlie Brown')
        expect(page).to have_content('1 filter active')
      end

      it 'filters contacts by company' do
        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Company', with: 'Design'
          click_button 'Apply Filters'
        end

        expect(page).to have_content('Alice Johnson')
        expect(page).not_to have_content('Bob Wilson')
        expect(page).not_to have_content('Charlie Brown')
      end

      it 'filters contacts by email' do
        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Email', with: 'alice@'
          click_button 'Apply Filters'
        end

        expect(page).to have_content('Alice Johnson')
        expect(page).not_to have_content('Bob Wilson')
        expect(page).not_to have_content('Charlie Brown')
      end

      it 'applies multiple filters simultaneously' do
        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Name', with: 'Alice'
          fill_in 'Company', with: 'Design'
          click_button 'Apply Filters'
        end

        expect(page).to have_content('Alice Johnson')
        expect(page).not_to have_content('Bob Wilson')
        expect(page).to have_content('2 filters active')
      end

      it 'shows clear filters link when filters are active' do
        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Name', with: 'Alice'
          click_button 'Apply Filters'
        end

        expect(page).to have_link('Clear Filters', href: contacts_path)

        click_link 'Clear Filters'

        expect(page).to have_content('Alice Johnson')
        expect(page).to have_content('Bob Wilson')
        expect(page).to have_content('Charlie Brown')
        expect(page).not_to have_content('filters active')
      end

      it 'filters by created date range' do
        old_contact = create(:contact, first_name: 'Old', last_name: 'Contact', created_at: 1.month.ago)

        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Created Since', with: 1.week.ago.strftime('%Y-%m-%d')
          click_button 'Apply Filters'
        end

        expect(page).to have_content('Alice Johnson')
        expect(page).not_to have_content('Old Contact')
      end

      it 'shows no results message when no contacts match filters' do
        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Name', with: 'NonExistentName'
          click_button 'Apply Filters'
        end

        expect(page).to have_content('No contacts found matching your filters')
        expect(page).to have_link('Clear Filters')
      end
    end

    describe 'sorting functionality' do
      it 'sorts contacts by name' do
        visit contacts_path

        # Click on the Name column header to sort
        within('thead') do
          click_link 'Name'
        end

        # Verify Alice appears before Bob and Charlie
        page_content = page.body
        alice_position = page_content.index('Alice Johnson')
        bob_position = page_content.index('Bob Wilson')
        charlie_position = page_content.index('Charlie Brown')

        expect(alice_position).to be < bob_position
        expect(bob_position).to be < charlie_position
      end

      it 'sorts contacts by email' do
        visit contacts_path

        within('thead') do
          click_link 'Email'
        end

        # Verify emails are sorted alphabetically
        page_content = page.body
        alice_position = page_content.index('alice@example.com')
        bob_position = page_content.index('bob@example.com')
        charlie_position = page_content.index('charlie@example.com')

        expect(alice_position).to be < bob_position
        expect(bob_position).to be < charlie_position
      end

      it 'sorts contacts by company' do
        visit contacts_path

        within('thead') do
          click_link 'Company'
        end

        # Verify companies are sorted alphabetically
        page_content = page.body
        design_position = page_content.index('Design Co')
        dev_position = page_content.index('Dev Corp')
        tech_position = page_content.index('Tech Inc')

        expect(design_position).to be < dev_position
        expect(dev_position).to be < tech_position
      end

      it 'reverses sort order when clicking the same column twice' do
        visit contacts_path

        # First click - ascending
        within('thead') do
          click_link 'Name'
        end

        first_sort_content = page.body
        alice_position_asc = first_sort_content.index('Alice Johnson')
        charlie_position_asc = first_sort_content.index('Charlie Brown')
        expect(alice_position_asc).to be < charlie_position_asc

        # Second click - descending
        within('thead') do
          click_link 'Name'
        end

        second_sort_content = page.body
        alice_position_desc = second_sort_content.index('Alice Johnson')
        charlie_position_desc = second_sort_content.index('Charlie Brown')
        expect(charlie_position_desc).to be < alice_position_desc
      end

      it 'maintains filters when sorting' do
        visit contacts_path

        # Apply a filter first
        within('.contacts-filter-form') do
          fill_in 'Company', with: 'Co'
          click_button 'Apply Filters'
        end

        # Should show only Design Co and Dev Corp
        expect(page).to have_content('Alice Johnson')
        expect(page).to have_content('Bob Wilson')
        expect(page).not_to have_content('Charlie Brown')

        # Now sort by name
        within('thead') do
          click_link 'Name'
        end

        # Filter should still be active
        expect(page).to have_content('Alice Johnson')
        expect(page).to have_content('Bob Wilson')
        expect(page).not_to have_content('Charlie Brown')
        expect(page).to have_content('1 filter active')
      end
    end

    describe 'pagination functionality' do
      before do
        # Create enough contacts to trigger pagination (25 per page)
        30.times do |i|
          create(:contact, first_name: "Contact#{i}", last_name: "User#{i}", email: "contact#{i}@example.com")
        end
      end

      it 'shows pagination information' do
        visit contacts_path

        expect(page).to have_content('Showing')
        expect(page).to have_content('to')
        expect(page).to have_content('of')
        expect(page).to have_content('contacts')
      end

      it 'paginates results' do
        visit contacts_path

        # Should have pagination links
        expect(page).to have_css('.pagination, [aria-label="Pagination"]')
      end

      it 'maintains filters across pages' do
        # Create contacts with specific names for filtering
        create(:contact, first_name: 'FilterTest1', last_name: 'User', email: 'filtertest1@example.com')
        create(:contact, first_name: 'FilterTest2', last_name: 'User', email: 'filtertest2@example.com')

        visit contacts_path

        within('.contacts-filter-form') do
          fill_in 'Name', with: 'FilterTest'
          click_button 'Apply Filters'
        end

        expect(page).to have_content('FilterTest1')
        expect(page).to have_content('FilterTest2')
        expect(page).to have_content('1 filter active')
      end
    end

    describe 'table actions' do
      it 'has view, edit, and delete links for each contact' do
        visit contacts_path

        within first('tbody tr') do
          expect(page).to have_link('View')
          expect(page).to have_link('Edit')
          expect(page).to have_link('Delete')
        end
      end

      it 'navigates to contact show page when clicking view' do
        visit contacts_path

        within first('tbody tr') do
          click_link 'View'
        end

        expect(page).to have_current_path(contact_path(Contact.first))
      end

      it 'navigates to contact edit page when clicking edit' do
        visit contacts_path

        within first('tbody tr') do
          click_link 'Edit'
        end

        expect(page).to have_current_path(edit_contact_path(Contact.first))
      end
    end
  end

  describe 'Show page' do
    let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson', email: 'alice@example.com', phone: '555-1234', company: 'Test Company', address: '123 Main St', city: 'Test City', state: 'TS', zip: '12345') }

    it 'displays contact details' do
      visit contact_path(contact)

      expect(page).to have_content('Alice Johnson')
      expect(page).to have_content('alice@example.com')
      expect(page).to have_content('555-1234')
      expect(page).to have_content('Test Company')
      expect(page).to have_content('123 Main St')
      expect(page).to have_content('Test City, TS 12345')
    end

    it 'has edit and delete buttons' do
      visit contact_path(contact)

      expect(page).to have_link('Edit', href: edit_contact_path(contact))
      expect(page).to have_link('Delete')
    end

    it 'displays contact creation date' do
      visit contact_path(contact)

      expect(page).to have_content('Contact created on')
      expect(page).to have_content(contact.created_at.strftime('%B %d, %Y'))
    end

    it 'has quick action buttons' do
      visit contact_path(contact)

      within('.bg-white.shadow-sm.rounded-lg') do
        expect(page).to have_content('Quick Actions')
        expect(page).to have_link('Edit Contact')
        expect(page).to have_link('Send Email')
        expect(page).to have_link('Call Contact')
        expect(page).to have_link('Delete Contact')
      end
    end

    it 'has clickable email and phone links' do
      visit contact_path(contact)

      expect(page).to have_link('alice@example.com', href: 'mailto:alice@example.com')
      expect(page).to have_link('555-1234', href: 'tel:555-1234')
    end

    it 'displays contact summary information' do
      visit contact_path(contact)

      expect(page).to have_content('Contact Summary')
      expect(page).to have_content('Account Age')
      expect(page).to have_content('Last Activity')
    end

    it 'handles missing optional fields gracefully' do
      contact_minimal = create(:contact, first_name: 'John', last_name: 'Doe', email: 'john@example.com', phone: nil, company: nil, address: nil)

      visit contact_path(contact_minimal)

      expect(page).to have_content('John Doe')
      expect(page).to have_content('No phone number')
      expect(page).to have_content('No company')
      expect(page).to have_content('No address provided')
    end
  end

  describe 'New page' do
    it 'displays the form' do
      visit new_contact_path

      expect(page).to have_content('Create New Contact')
      expect(page).to have_content('Personal Information')
      expect(page).to have_content('Address Information')
      expect(page).to have_field('First name')
      expect(page).to have_field('Last name')
      expect(page).to have_field('Email')
      expect(page).to have_field('Company')
      expect(page).to have_field('Phone')
      expect(page).to have_field('Street Address')
      expect(page).to have_field('City')
      expect(page).to have_field('State / Province')
      expect(page).to have_field('ZIP / Postal Code')
    end

    it 'has helpful placeholders' do
      visit new_contact_path

      expect(page).to have_field('First name', placeholder: 'John')
      expect(page).to have_field('Last name', placeholder: 'Doe')
      expect(page).to have_field('Email', placeholder: 'john.doe@example.com')
      expect(page).to have_field('Phone', placeholder: '+1 (555) 123-4567')
      expect(page).to have_field('Company', placeholder: 'Acme Corporation')
      expect(page).to have_field('Street Address', placeholder: '123 Main Street')
      expect(page).to have_field('City', placeholder: 'San Francisco')
      expect(page).to have_field('State / Province', placeholder: 'CA')
      expect(page).to have_field('ZIP / Postal Code', placeholder: '94102')
    end

    it 'creates a new contact with valid data' do
      visit new_contact_path

      fill_in 'First name', with: 'Test'
      fill_in 'Last name', with: 'Contact'
      fill_in 'Email', with: 'test@example.com'
      fill_in 'Company', with: 'Test Company'
      fill_in 'Phone', with: '555-9999'
      fill_in 'Street Address', with: '123 Test St'
      fill_in 'City', with: 'Test City'
      fill_in 'State / Province', with: 'TS'
      fill_in 'ZIP / Postal Code', with: '12345'

      click_button 'Create Contact'

      expect(page).to have_current_path(contacts_path)
      expect(page).to have_content('Test Contact')
      expect(page).to have_content('New Contact Created')
    end

    it 'shows errors for invalid data' do
      visit new_contact_path

      click_button 'Create Contact'

      expect(page).to have_content("can't be blank")
      expect(page).to have_content('Please fix the following errors:')
    end

    it 'shows errors for duplicate email' do
      existing_contact = create(:contact, email: 'existing@example.com')

      visit new_contact_path

      fill_in 'First name', with: 'Test'
      fill_in 'Last name', with: 'Contact'
      fill_in 'Email', with: 'existing@example.com'

      click_button 'Create Contact'

      expect(page).to have_content('Email has already been taken')
    end

    it 'has cancel button that returns to contacts index' do
      visit new_contact_path

      click_link 'Cancel'

      expect(page).to have_current_path(contacts_path)
    end
  end

  describe 'Edit page' do
    let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson', email: 'alice@example.com', company: 'Original Company') }

    it 'displays the form with current data' do
      visit edit_contact_path(contact)

      expect(page).to have_content('Edit Contact: Alice Johnson')
      expect(page).to have_field('First name', with: 'Alice')
      expect(page).to have_field('Last name', with: 'Johnson')
      expect(page).to have_field('Email', with: 'alice@example.com')
      expect(page).to have_field('Company', with: 'Original Company')
    end

    it 'updates the contact with valid data' do
      visit edit_contact_path(contact)

      fill_in 'First name', with: 'Updated'
      fill_in 'Company', with: 'Updated Company'
      click_button 'Update Contact'

      expect(page).to have_current_path(contact_path(contact))
      expect(page).to have_content('Updated Johnson')
      expect(page).to have_content('Updated Company')
      expect(page).to have_content('Contact Updated')
    end

    it 'shows errors for invalid data' do
      visit edit_contact_path(contact)

      fill_in 'First name', with: ''
      fill_in 'Email', with: 'invalid-email'
      click_button 'Update Contact'

      expect(page).to have_content("can't be blank")
      expect(page).to have_content('Invalid e-mail address')
    end

    it 'has cancel button that returns to contacts index' do
      visit edit_contact_path(contact)

      click_link 'Cancel'

      expect(page).to have_current_path(contacts_path)
    end

    it 'shows correct button text for update' do
      visit edit_contact_path(contact)

      expect(page).to have_button('Update Contact')
      expect(page).not_to have_button('Create Contact')
    end
  end

  describe 'Delete functionality' do
    let!(:contact) { create(:contact, first_name: 'Alice', last_name: 'Johnson') }

    it 'deletes a contact from the index page' do
      visit contacts_path

      accept_confirm do
        click_link 'Delete'
      end

      expect(page).not_to have_content('Alice Johnson')
      expect(page).to have_content('Contact Deleted')
    end

    it 'deletes a contact from the show page' do
      visit contact_path(contact)

      accept_confirm do
        click_link 'Delete'
      end

      expect(page).to have_current_path(contacts_path)
      expect(page).not_to have_content('Alice Johnson')
      expect(page).to have_content('Contact Deleted')
    end

    it 'shows confirmation dialog before deleting' do
      visit contacts_path

      # The confirmation dialog is handled by the browser and turbo-confirm
      # We can verify the data attribute is present
      delete_link = find('a', text: 'Delete')
      expect(delete_link['data-turbo-confirm']).to be_present
    end
  end

  describe 'Navigation and Layout' do
    it 'has proper responsive design elements' do
      visit contacts_path

      # Check for responsive classes
      expect(page).to have_css('.sm\\:grid-cols-2')
      expect(page).to have_css('.lg\\:grid-cols-3')
      expect(page).to have_css('.overflow-x-auto')
    end

    it 'has proper accessibility elements' do
      visit contacts_path

      # Check for screen reader text
      expect(page).to have_css('.sr-only', text: 'Actions')

      # Check for proper table headers
      expect(page).to have_css('th[scope="col"]')
    end

    it 'maintains consistent styling across pages' do
      # Check index page
      visit contacts_path
      expect(page).to have_css('.bg-white.shadow-sm.rounded-lg')

      # Check show page
      visit contact_path(create(:contact))
      expect(page).to have_css('.bg-white.shadow-sm.rounded-lg')

      # Check new page
      visit new_contact_path
      expect(page).to have_css('.bg-white.shadow-sm.rounded-lg')
    end

    it 'displays page titles correctly' do
      visit contacts_path
      expect(page).to have_content('Contacts')

      contact = create(:contact, first_name: 'John', last_name: 'Doe')
      visit contact_path(contact)
      expect(page).to have_content('John Doe')

      visit new_contact_path
      expect(page).to have_content('Create New Contact')

      visit edit_contact_path(contact)
      expect(page).to have_content('Edit Contact: John Doe')
    end
  end

  describe 'Error handling' do
    it 'handles non-existent contact gracefully' do
      expect {
        visit contact_path(99999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'maintains form data when validation fails' do
      visit new_contact_path

      fill_in 'First name', with: 'Test'
      fill_in 'Company', with: 'Test Company'
      # Leave required last_name empty

      click_button 'Create Contact'

      # Form should maintain the data that was entered
      expect(page).to have_field('First name', with: 'Test')
      expect(page).to have_field('Company', with: 'Test Company')
    end
  end
end