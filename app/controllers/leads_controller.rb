class LeadsController < ApplicationController
  before_action :authenticate_user!, except: [ "external_form" ]
  before_action :set_lead, only: [ :show, :edit, :update, :destroy ]

  def index
    @leads = Lead.includes(:assigned_to)

    # Apply filters
    @leads = @leads.search_by_name(params[:name]) if params[:name].present?
    @leads = @leads.search_by_company(params[:company]) if params[:company].present?
    @leads = @leads.created_since(params[:created_since]) if params[:created_since].present?
    @leads = @leads.created_before(params[:created_before]) if params[:created_before].present?
    @leads = @leads.with_status(params[:status]) if params[:status].present?
    @leads = @leads.where(assigned_to_id: params[:assigned_to]) if params[:assigned_to].present?

    # Apply sorting
    @leads = apply_sorting(@leads)

    @leads = @leads.page(params[:page])
                   .per(25)

    # For the filter dropdowns
    @lead_statuses = Lead.status
    @users = User.where(approved: true).order(:first_name, :last_name)

    # For sorting
    @current_sort = params[:sort] || "created_at"
    @current_direction = params[:direction] || "desc"
  end

  def new
    @lead = Lead.new
    @lead_owner = User.all.map(&:email)
    @lead_status = Lead.status if Lead.respond_to?(:status)
    @lead_sources = Lead.sources if Lead.respond_to?(:sources)
    @lead_interests = Lead.interests if Lead.respond_to?(:interests)
  end

  def show
    @lead_owner = User.all.map(&:email)
    @lead_status = Lead.status if Lead.respond_to?(:status)
    @lead_sources = Lead.sources if Lead.respond_to?(:sources)
    @lead_interests = Lead.interests if Lead.respond_to?(:interests)
  end

  def create
    @lead = Lead.new(lead_params)
    @lead.assigned_to = User.find_by(email: @lead.lead_owner) if @lead.lead_owner.present?

    if @lead.save
      # LeadMailer.notify_new_lead(@lead.lead_owner, @lead).deliver if defined?(LeadMailer)
      redirect_to lead_path(@lead), notice: "New Lead Created"
    else
      # Reload form data for re-render
      @lead_owner = User.all.map(&:email)
      @lead_status = Lead.status if Lead.respond_to?(:status)
      @lead_sources = Lead.sources if Lead.respond_to?(:sources)
      @lead_interests = Lead.interests if Lead.respond_to?(:interests)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @lead_owner = User.all.map(&:email)
    @lead_status = Lead.status if Lead.respond_to?(:status)
    @lead_sources = Lead.sources if Lead.respond_to?(:sources)
    @lead_interests = Lead.interests if Lead.respond_to?(:interests)
  end

  def update
    if params[:commit] == "Convert"
      convert_lead
    else
      if @lead.update(lead_params)
        # LeadMailer.notify_updated_lead(@lead.lead_owner, @lead).deliver if defined?(LeadMailer)
        redirect_to lead_path(@lead), notice: "Lead Updated"
      else
        # Reload form data for re-render
        @lead_owner = User.all.map(&:email)
        @lead_status = Lead.status if Lead.respond_to?(:status)
        @lead_sources = Lead.sources if Lead.respond_to?(:sources)
        @lead_interests = Lead.interests if Lead.respond_to?(:interests)
        render :edit, status: :unprocessable_content
      end
    end
  end

  def destroy
    if @lead.destroy
      flash[:notice] = "Lead Deleted"
      redirect_to leads_path
    else
      flash[:error] = "Lead could not be deleted"
      redirect_back(fallback_location: leads_path)
    end
  end

  def external_form
    @lead = Lead.new(lead_params)
    @lead.lead_source = "web"
    @lead.lead_status = "new"
    @lead.lead_owner = User.first&.email || "admin@example.com" # Set default owner
    @lead.assigned_to = User.first if User.any?

    if @lead.save
      redirect_to root_path, notice: "Thank you for your interest!"
    else
      render :external_form, status: :unprocessable_content
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def apply_sorting(scope)
    sort_column = params[:sort] || "created_at"
    sort_direction = params[:direction] || "desc"

    # Validate sort column to prevent SQL injection
    allowed_columns = %w[first_name last_name email company lead_status assigned_to created_at]
    sort_column = "created_at" unless allowed_columns.include?(sort_column)

    # Validate sort direction
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    case sort_column
    when "first_name", "last_name"
      # For name sorting, combine first and last name
      if sort_direction == "asc"
        scope.order(Arel.sql("CONCAT(first_name, ' ', last_name) ASC"))
      else
        scope.order(Arel.sql("CONCAT(first_name, ' ', last_name) DESC"))
      end
    when "assigned_to"
      # Join with users table to sort by assigned user name
      if sort_direction == "asc"
        scope.joins(:assigned_to).order("users.first_name ASC, users.last_name ASC")
      else
        scope.joins(:assigned_to).order("users.first_name DESC, users.last_name DESC")
      end
    else
      if sort_direction == "asc"
        scope.order("#{sort_column} ASC")
      else
        scope.order("#{sort_column} DESC")
      end
    end
  end

  def lead_params
    params.require(:lead).permit(:first_name, :last_name, :email, :phone, :company,
                                 :address, :city, :state, :zip, :comments, :lead_owner,
                                 :lead_status, :lead_source, :interested_in)
  end

  def convert
    # Show conversion form
    @lead_owner = User.all.map(&:email)
    @lead_status = Lead.status if Lead.respond_to?(:status)
    @lead_sources = Lead.sources if Lead.respond_to?(:sources)
    @lead_interests = Lead.interests if Lead.respond_to?(:interests)
  end

  def convert_lead
    # Simplified conversion logic for now
    @lead.update(lead_params) if params[:lead].present?
    flash[:notice] = "Lead conversion feature needs to be implemented"
    redirect_to @lead
  end
end
