class OpportunitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_opportunity, only: [ :show, :update, :destroy ]

  def index
    @opportunities = Opportunity.all

    # Apply filters using scopes
    @opportunities = @opportunities.by_name(params[:name]) if params[:name].present?
    @opportunities = @opportunities.by_account(params[:account_name]) if params[:account_name].present?
    @opportunities = @opportunities.by_owner(params[:owner]) if params[:owner].present?
    @opportunities = @opportunities.by_stage(params[:stage]) if params[:stage].present?
    @opportunities = @opportunities.by_type(params[:type]) if params[:type].present?
    @opportunities = @opportunities.created_since(params[:created_since]) if params[:created_since].present?
    @opportunities = @opportunities.created_before(params[:created_before]) if params[:created_before].present?
    @opportunities = @opportunities.closing_after(params[:closing_after]) if params[:closing_after].present?
    @opportunities = @opportunities.closing_before(params[:closing_before]) if params[:closing_before].present?

    # Apply sorting
    @opportunities = apply_sorting(@opportunities)

    # Pagination
    @opportunities = @opportunities.page(params[:page]).per(25)

    # For sorting headers and filters
    @current_sort = params[:sort] || "created_at"
    @current_direction = params[:direction] || "desc"
    @stages = Opportunity.stages
    @types = Opportunity.types
  end

  def new
    @opportunity = Opportunity.new
  end

  def show
  end

  def create
    @opportunity = Opportunity.new(opportunity_params)
    if @opportunity.save
      redirect_to opportunity_path(@opportunity), flash: { notice: "New Opportunity Created" }
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @opportunity = Opportunity.find(params[:id])
  end

  def update
    if @opportunity.update(opportunity_params)
      redirect_to opportunity_path(@opportunity), notice: "Opportunity Successfully Updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @opportunity.destroy
      flash[:notice] = "Opportunity Deleted"
      redirect_back(fallback_location: opportunities_path)
    else
      flash[:error] = "Opportunity could not be deleted"
      redirect_back(fallback_location: opportunities_path)
    end
  end

  private

  def set_opportunity
    @opportunity = Opportunity.find(params[:id])
  end

  def opportunity_params
    params.require(:opportunity).permit(:opportunity_name, :account_name, :type, :amount, :stage, :owner, :probability, :contact_name, :comments, :closing_date)
  end

  def apply_sorting(scope)
    sort_column = params[:sort] || "created_at"
    sort_direction = params[:direction] || "desc"

    # Validate sort column to prevent SQL injection
    allowed_columns = %w[opportunity_name account_name owner stage amount closing_date created_at]
    sort_column = "created_at" unless allowed_columns.include?(sort_column)

    # Validate sort direction
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    scope.order(sort_column => sort_direction)
  end
end
