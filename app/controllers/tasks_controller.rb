class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :show, :update, :destroy ]

  def index
    @tasks = Task.includes(:assignee).all

    # Apply filters using scopes
    @tasks = @tasks.by_title(params[:title]) if params[:title].present?
    @tasks = @tasks.by_priority(params[:priority]) if params[:priority].present?
    @tasks = @tasks.by_assignee(params[:assignee_id]) if params[:assignee_id].present?
    if params[:status].present?
      @tasks = params[:status] == "completed" ? @tasks.completed : @tasks.pending
    end
    @tasks = @tasks.created_since(params[:created_since]) if params[:created_since].present?
    @tasks = @tasks.created_before(params[:created_before]) if params[:created_before].present?
    @tasks = @tasks.due_after(params[:due_after]) if params[:due_after].present?
    @tasks = @tasks.due_before(params[:due_before]) if params[:due_before].present?

    # Apply sorting
    @tasks = apply_sorting(@tasks)

    # Pagination
    @tasks = @tasks.page(params[:page]).per(25)

    # For sorting headers and filters
    @current_sort = params[:sort] || "due_date"
    @current_direction = params[:direction] || "asc"
    @users = User.where(approved: true).order(:first_name, :last_name)
    @priorities = [["High", "high"], ["Medium", "medium"], ["Low", "low"]]
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
      render :new, status: :unprocessable_content
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
      render :edit, status: :unprocessable_content
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

  def apply_sorting(scope)
    sort_column = params[:sort] || "due_date"
    sort_direction = params[:direction] || "asc"

    # Validate sort column to prevent SQL injection
    allowed_columns = %w[title due_date priority completed created_at assignee_id]
    sort_column = "due_date" unless allowed_columns.include?(sort_column)

    # Validate sort direction
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    # Handle assignee sorting with join
    if sort_column == "assignee_id"
      scope.joins(:assignee).order("users.first_name #{sort_direction}, users.last_name #{sort_direction}")
    else
      scope.order(sort_column => sort_direction)
    end
  end
end
