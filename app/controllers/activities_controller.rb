class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact
  before_action :set_activity, only: [ :show, :edit, :update, :destroy, :complete ]

  def index
    @activities = @contact.activities.recent
  end

  def show
    # Show action can respond to JSON or redirect to contact page
    respond_to do |format|
      format.html { redirect_to contact_path(@contact) }
      format.json { render json: @activity }
    end
  end

  def new
    @activity = @contact.activities.build(due_date: 1.day.from_now)
  end

  def create
    @activity = @contact.activities.build(activity_params)
    @activity.user = current_user unless @activity.user.present?

    # Handle timezone conversion if provided
    if params[:user_timezone].present? && @activity.due_date.present?
      begin
        # Parse the date in the user's timezone and convert to UTC for storage
        tz = TZInfo::Timezone.get(params[:user_timezone])
        local_time = Time.parse(@activity.due_date.to_s)
        @activity.due_date = tz.local_to_utc(local_time)
      rescue => e
        Rails.logger.warn "Timezone conversion failed: #{e.message}"
        # Fall back to treating it as UTC if timezone conversion fails
      end
    end

    if @activity.save
      respond_to do |format|
        format.html { redirect_to contact_path(@contact), notice: "Activity scheduled successfully." }
        format.json { render json: @activity, status: :created }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to contact_path(@contact), alert: "Failed to schedule activity: #{@activity.errors.full_messages.join(', ')}" }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to contact_path(@contact), notice: "Activity updated successfully."
    else
      redirect_to contact_path(@contact), alert: "Failed to update activity: #{@activity.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @activity.destroy
    redirect_to contact_path(@contact), notice: "Activity deleted successfully."
  end

  def complete
    @activity.update(completed_at: Time.current)
    redirect_to contact_path(@contact), notice: "Activity marked as completed."
  end

  private

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def set_activity
    @activity = @contact.activities.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:activity_type, :title, :description, :due_date, :priority, :duration, :user_id)
  end
end
