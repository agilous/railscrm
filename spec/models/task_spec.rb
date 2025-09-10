require 'rails_helper'

RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  describe 'associations' do
    it { is_expected.to belong_to(:assignee).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'scopes' do
    before do
      create(:task, :completed, title: 'Completed Task')
      create(:task, :pending, title: 'Pending Task')
      create(:task, completed: false, title: 'Another Pending Task')
    end

    describe '.completed' do
      it 'returns only completed tasks' do
        completed_tasks = Task.completed

        expect(completed_tasks.count).to eq(1)
        expect(completed_tasks.first.title).to eq('Completed Task')
        expect(completed_tasks.first.completed).to be true
      end
    end

    describe '.pending' do
      it 'returns only pending tasks' do
        pending_tasks = Task.pending

        expect(pending_tasks.count).to eq(2)
        expect(pending_tasks.pluck(:completed)).to all(be false)
      end
    end
  end

  describe 'completion status' do
    it 'defaults to incomplete' do
      task = build(:task)

      expect(task.completed).to be false
    end

    it 'can be created as completed' do
      task = build(:task, :completed)

      expect(task.completed).to be true
    end

    it 'can be created as pending' do
      task = build(:task, :pending)

      expect(task.completed).to be false
    end
  end

  describe 'due date handling' do
    it 'can have a due date' do
      due_date = 1.week.from_now.to_date
      task = build(:task, due_date: due_date)

      expect(task.due_date).to eq(due_date)
    end

    it 'can be created due today' do
      task = build(:task, :due_today)

      expect(task.due_date).to eq(Date.current)
    end

    it 'can be created as overdue' do
      task = build(:task, :overdue)

      expect(task.due_date).to be < Date.current
      expect(task.completed).to be false
    end
  end

  describe 'priority levels' do
    it 'defaults to medium priority' do
      task = build(:task)

      expect(task.priority).to eq('medium')
    end

    it 'can be created with high priority' do
      task = build(:task, :high_priority)

      expect(task.priority).to eq('high')
    end

    it 'can be created with low priority' do
      task = build(:task, :low_priority)

      expect(task.priority).to eq('low')
    end
  end

  describe 'task details' do
    it 'can store complete task information' do
      user = create(:user)
      task = create(:task,
                   assignee: user,
                   title: 'Important Task',
                   description: 'This task requires immediate attention.',
                   due_date: 3.days.from_now,
                   priority: 'high',
                   completed: false)

      expect(task).to be_valid
      expect(task.assignee).to eq(user)
      expect(task.title).to eq('Important Task')
      expect(task.description).to eq('This task requires immediate attention.')
      expect(task.due_date.to_date).to eq(3.days.from_now.to_date)
      expect(task.priority).to eq('high')
      expect(task.completed).to be false
    end

    it 'can exist without description' do
      task = build(:task, :no_description)

      expect(task.description).to be_nil
      expect(task).to be_valid
    end
  end

  describe 'required fields validation' do
    it 'is valid with title and assignee' do
      user = create(:user)
      task = build(:task, title: 'Test Task', assignee: user)

      expect(task).to be_valid
    end

    it 'is invalid without title' do
      task = build(:task, title: nil)

      expect(task).not_to be_valid
      expect(task.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without assignee' do
      task = build(:task, assignee: nil)

      expect(task).not_to be_valid
      expect(task.errors[:assignee]).to include("must exist")
    end
  end
end
