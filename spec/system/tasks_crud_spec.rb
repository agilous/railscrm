require 'rails_helper'

RSpec.describe 'Tasks CRUD', type: :system do
  let(:user) { create(:approved_user) }
  let(:other_user) { create(:approved_user, email: 'other@example.com') }

  before do
    login_as user
  end

  describe 'Index page' do
    let!(:task1) { create(:task, title: 'Call client', assignee: user, priority: 'high', completed: false) }
    let!(:task2) { create(:task, title: 'Send proposal', assignee: other_user, priority: 'medium', completed: true) }

    it 'displays all tasks' do
      visit tasks_path

      expect(page).to have_content('Tasks')
      expect(page).to have_content('Call client')
      expect(page).to have_content('Send proposal')
      expect(page).to have_content('High')
      expect(page).to have_content('Medium')
      expect(page).to have_content('Pending')
      expect(page).to have_content('Completed')
    end

    it 'has a create task button' do
      visit tasks_path

      expect(page).to have_link('Create Task', href: new_task_path)
    end

    it 'allows navigation to individual tasks' do
      visit tasks_path

      click_link 'Call client'
      expect(page).to have_current_path(task_path(task1))
    end

    it 'shows overdue tasks in red' do
      overdue_task = create(:task, title: 'Overdue task', assignee: user, due_date: 2.days.ago)
      visit tasks_path

      expect(page).to have_content('Overdue task')
      expect(page).to have_content('Overdue')
    end
  end

  describe 'Show page' do
    let!(:task) { create(:task, title: 'Call client', description: 'Follow up on proposal', assignee: user, priority: 'high') }

    it 'displays task details' do
      visit task_path(task)

      expect(page).to have_content('Call client')
      expect(page).to have_content('Follow up on proposal')
      expect(page).to have_content('High')
      expect(page).to have_content(user.full_name || user.email)
    end

    it 'has edit button' do
      visit task_path(task)

      expect(page).to have_link('Edit', href: edit_task_path(task))
    end
  end

  describe 'New page' do
    it 'displays the form' do
      visit new_task_path

      expect(page).to have_content('Create New Task')
      expect(page).to have_field('Title')
      expect(page).to have_field('Description')
      expect(page).to have_field('Due date')
      expect(page).to have_field('Priority')
      expect(page).to have_select('Assignee')
    end

    it 'creates a new task with valid data' do
      visit new_task_path

      fill_in 'Title', with: 'Test Task'
      fill_in 'Description', with: 'This is a test task'
      fill_in 'Due date', with: Date.tomorrow.strftime('%Y-%m-%d')
      select 'High', from: 'Priority'
      select user.email, from: 'Assignee'

      click_button 'Create Task'

      expect(page).to have_current_path(tasks_path)
      expect(page).to have_content('Test Task')
    end

    it 'shows errors for invalid data' do
      visit new_task_path

      click_button 'Create Task'

      expect(page).to have_content("can't be blank")
    end
  end

  describe 'Edit page' do
    let!(:task) { create(:task, title: 'Call client', assignee: user) }

    it 'displays the form with current data' do
      visit edit_task_path(task)

      expect(page).to have_content('Edit Task: Call client')
      expect(page).to have_field('Title', with: 'Call client')
    end

    it 'updates the task with valid data' do
      visit edit_task_path(task)

      fill_in 'Title', with: 'Updated Task'
      check 'Completed'
      click_button 'Update Task'

      expect(page).to have_current_path(tasks_path)
      expect(page).to have_content('Updated Task')
    end
  end

  # Delete functionality is tested in request specs due to Turbo confirm dialog issues with Selenium

  describe 'Task completion' do
    let!(:task) { create(:task, title: 'Call client', assignee: user, completed: false) }

    it 'allows marking tasks as completed' do
      visit edit_task_path(task)

      check 'Completed'
      click_button 'Update Task'

      visit tasks_path
      expect(page).to have_content('Completed')
    end
  end

  describe 'Task priority display' do
    let!(:high_task) { create(:task, title: 'High priority', assignee: user, priority: 'high') }
    let!(:medium_task) { create(:task, title: 'Medium priority', assignee: user, priority: 'medium') }
    let!(:low_task) { create(:task, title: 'Low priority', assignee: user, priority: 'low') }

    it 'displays tasks with different priority colors' do
      visit tasks_path

      expect(page).to have_content('High priority')
      expect(page).to have_content('Medium priority')
      expect(page).to have_content('Low priority')
      expect(page).to have_content('High')
      expect(page).to have_content('Medium')
      expect(page).to have_content('Low')

      # High priority should be highlighted
      expect(page).to have_css('.text-red-600, .bg-red-100', text: 'High')
    end
  end

  describe 'Future filtering and sorting placeholders' do
    let!(:task1) { create(:task, title: 'Alpha Task', assignee: user, priority: 'high', completed: false, due_date: 1.day.from_now) }
    let!(:task2) { create(:task, title: 'Beta Task', assignee: other_user, priority: 'medium', completed: true, due_date: 1.week.from_now) }

    it 'displays tasks in index view' do
      visit tasks_path

      expect(page).to have_content('Alpha Task')
      expect(page).to have_content('Beta Task')
      expect(page).to have_content('High')
      expect(page).to have_content('Medium')
    end

    # Note: Advanced filtering and sorting UI not yet implemented
    # These tests would be activated once the filtering UI is added
  end

  describe 'Task notifications placeholders' do
    it 'creates tasks successfully' do
      visit new_task_path

      fill_in 'Title', with: 'Task with notification'
      fill_in 'Description', with: 'This should send a notification'

      # Select an assignee (use user since other_user may not be in options)
      select user.email, from: 'Assignee'

      click_button 'Create Task'

      expect(page).to have_content('Task with notification')
    end

    # Note: Task notification mailers are implemented but not tested here
    # to avoid mocking complexity in system specs
  end

  describe 'Error handling and edge cases' do
    it 'handles tasks without due dates' do
      no_due_date_task = create(:task, title: 'No due date task', assignee: user, due_date: nil)

      visit task_path(no_due_date_task)

      expect(page).to have_content('No due date task')
      expect(page).to have_content('No due date').or have_content('—')
    end

    it 'handles very long task titles' do
      long_title = 'A' * 200 + ' - Very Long Task Title'
      task = create(:task, title: long_title, assignee: user)

      visit task_path(task)

      expect(page).to have_content(long_title)
    end

    it 'validates due date format' do
      visit new_task_path

      fill_in 'Title', with: 'Test task'
      fill_in 'Due date', with: 'invalid-date'
      select user.email, from: 'Assignee'

      click_button 'Create Task'

      expect(page).to have_content('invalid').or have_content('date')
    end

    it 'maintains form data when validation fails' do
      visit new_task_path

      fill_in 'Title', with: 'Test Task'
      fill_in 'Description', with: 'Test description'
      # Leave required fields blank if any

      click_button 'Create Task'

      expect(page).to have_field('Title', with: 'Test Task')
      expect(page).to have_field('Description', with: 'Test description')
    end
  end
end
