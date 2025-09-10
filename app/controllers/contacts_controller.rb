class ContactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact, only: [ :show, :update, :destroy ]

  def index
    @contacts = Contact.all
  end

  def new
    @contact = Contact.new
  end

  def show
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      redirect_to contacts_path, flash: { notice: "New Contact Created" }
    else
      render json: { errors: @contact.errors }, status: :unprocessable_entity
    end
  end

  def edit
    @contact = Contact.find(params[:id])
  end

  def update
    if @contact.update(contact_params)
      redirect_to contact_path(@contact), notice: "Contact Updated"
    else
      render json: { errors: @contact.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @contact == current_user
      flash[:notice] = "Cannot delete yourself"
      redirect_back(fallback_location: contacts_path)
    elsif @contact.destroy
      flash[:notice] = "Contact Deleted"
      redirect_back(fallback_location: contacts_path)
    else
      flash[:error] = "Contact could not be deleted"
      redirect_back(fallback_location: contacts_path)
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :company, :email, :phone, :address, :city, :state, :zip)
  end
end
