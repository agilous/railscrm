class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :show, :update, :destroy ]

  def index
    @tasks = Task.all
  end

  def new
    @task = Task.new
  end

  def show
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to tasks_path, flash: { notice: "New Task Created" }
      # Send email notification if needed
      if @task.assignee
        TaskMailer.notify_new_task(@task.assignee, @task).deliver_later
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @task = Task.find(params[:id])
  end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, flash: { notice: "Task Updated" }
      # Send email notification if needed
      if @task.assignee
        TaskMailer.notify_updated_task(@task.assignee, @task).deliver_later
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      flash[:notice] = "Task Deleted"
      redirect_back(fallback_location: tasks_path)
    else
      flash[:error] = "Task could not be deleted"
      redirect_back(fallback_location: tasks_path)
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :due_date, :completed, :priority, :assignee_id)
  end
end
