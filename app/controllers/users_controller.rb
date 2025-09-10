class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only, only: [ :index, :approve ]
  before_action :set_user, only: [ :approve ]

  def index
    @users = User.all
  end

  def dashboard
    @user = current_user
  end

  def approve
    @user.update(approved: true)
    redirect_to admin_path, notice: "User has been approved."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def admin_only
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end
end
