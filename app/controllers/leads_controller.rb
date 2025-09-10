class LeadsController < ApplicationController
  before_action :authenticate_user!, except: [ "external_form" ]
  before_action :set_lead, only: [ :show, :edit, :update, :destroy ]

  def index
    @leads = Lead.all
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
      render :new, status: :unprocessable_entity
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
        render :edit, status: :unprocessable_entity
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
      render :external_form, status: :unprocessable_entity
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
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
