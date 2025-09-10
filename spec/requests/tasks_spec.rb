require 'rails_helper'

RSpec.describe 'Tasks', type: :request do
  let(:user) { create(:approved_user) }
  let(:task) { create(:task) }

  before do
    sign_in user
  end

  describe 'GET /tasks' do
    it 'returns a successful response' do
      get tasks_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /tasks/:id' do
    it 'returns a successful response' do
      get task_path(task)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /tasks/new' do
    it 'returns a successful response' do
      get new_task_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /tasks' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          task: {
            title: 'Test Task',
            description: 'Test task description',
            due_date: Date.tomorrow,
            assignee_id: user.id,
            priority: 'high',
            completed: false
          }
        }
      end

      it 'creates a new task' do
        expect {
          post tasks_path, params: valid_attributes
        }.to change(Task, :count).by(1)
      end

      it 'redirects to tasks index' do
        post tasks_path, params: valid_attributes
        expect(response).to redirect_to(tasks_path)
      end
    end
  end

  describe 'PATCH /tasks/:id' do
    context 'with valid parameters' do
      let(:new_attributes) do
        { task: { title: 'Updated Task Name' } }
      end

      it 'updates the task' do
        patch task_path(task), params: new_attributes
        task.reload
        expect(task.title).to eq('Updated Task Name')
      end

      it 'redirects to tasks index' do
        patch task_path(task), params: new_attributes
        expect(response).to redirect_to(tasks_path)
      end
    end
  end

  describe 'DELETE /tasks/:id' do
    let!(:task_to_delete) { create(:task) }

    it 'destroys the task' do
      expect {
        delete task_path(task_to_delete)
      }.to change(Task, :count).by(-1)
    end

    it 'redirects to tasks index' do
      delete task_path(task_to_delete)
      expect(response).to redirect_to(tasks_path)
    end
  end
end
