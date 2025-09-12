class OpportunitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_opportunity, only: [ :show, :update, :destroy ]

  def index
    @opportunities = Opportunity.all
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
end
