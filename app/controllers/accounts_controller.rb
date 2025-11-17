class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [ :show, :update, :destroy ]

  def index
    @accounts = Account.all

    # Apply filters using scopes
    @accounts = @accounts.by_name(params[:name]) if params[:name].present?
    @accounts = @accounts.by_email(params[:email]) if params[:email].present?
    @accounts = @accounts.by_assigned_to(params[:assigned_to]) if params[:assigned_to].present?
    @accounts = @accounts.created_since(params[:created_since]) if params[:created_since].present?
    @accounts = @accounts.created_before(params[:created_before]) if params[:created_before].present?

    # Apply sorting
    @accounts = apply_sorting(@accounts)

    # Pagination
    @accounts = @accounts.page(params[:page]).per(25)

    # For sorting headers
    @current_sort = params[:sort] || "created_at"
    @current_direction = params[:direction] || "desc"
  end

  def new
    @account = Account.new
  end

  def show
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to accounts_path, flash: { notice: "New Account Created" }
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @account = Account.find(params[:id])
  end

  def update
    if @account.update(account_params)
      redirect_to account_path(@account), notice: "Account Updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @account.destroy
      flash[:notice] = "Account Deleted"
      redirect_back(fallback_location: accounts_path)
    else
      flash[:error] = "Account could not be deleted"
      redirect_back(fallback_location: accounts_path)
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :phone, :website, :email, :address, :city, :state, :zip, :assigned_to)
  end

  def apply_sorting(scope)
    sort_column = params[:sort] || "created_at"
    sort_direction = params[:direction] || "desc"

    # Validate sort column to prevent SQL injection
    allowed_columns = %w[name email phone website assigned_to created_at]
    sort_column = "created_at" unless allowed_columns.include?(sort_column)

    # Validate sort direction
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    scope.order(sort_column => sort_direction)
  end
end
