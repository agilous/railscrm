class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [ :show, :update, :destroy ]

  def index
    @accounts = Account.all
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
end
