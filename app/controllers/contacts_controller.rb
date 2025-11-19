class ContactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact, only: [ :show, :update, :destroy ]

  def index
    @contacts = Contact.all

    # Apply filters using scopes
    @contacts = @contacts.by_name(params[:name]) if params[:name].present?
    @contacts = @contacts.by_company(params[:company]) if params[:company].present?
    @contacts = @contacts.by_email(params[:email]) if params[:email].present?
    @contacts = @contacts.created_since(params[:created_since]) if params[:created_since].present?
    @contacts = @contacts.created_before(params[:created_before]) if params[:created_before].present?

    # Apply sorting
    @contacts = apply_sorting(@contacts)

    # Pagination
    @contacts = @contacts.page(params[:page]).per(25)

    # For sorting headers
    @current_sort = params[:sort] || "created_at"
    @current_direction = params[:direction] || "desc"
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
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @contact = Contact.find(params[:id])
  end

  def update
    if @contact.update(contact_params)
      redirect_to contact_path(@contact), notice: "Contact Updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @contact.destroy
      flash[:notice] = "Contact Deleted"
      redirect_to contacts_path
    else
      flash[:error] = "Contact could not be deleted"
      redirect_back(fallback_location: contacts_path)
    end
  end

  private

  def set_contact
    @contact = Contact.includes(
      :activities,
      :deals,
      notes: [ :user, :note_associations ]
    ).find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :company, :email, :phone, :address, :city, :state, :zip)
  end

  def apply_sorting(scope)
    sort_column = params[:sort] || "created_at"
    sort_direction = params[:direction] || "desc"

    # Validate sort column to prevent SQL injection
    allowed_columns = %w[first_name last_name email company phone created_at]
    sort_column = "created_at" unless allowed_columns.include?(sort_column)

    # Validate sort direction
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    case sort_column
    when "first_name"
      scope.order(first_name: sort_direction, last_name: sort_direction)
    when "last_name"
      scope.order(last_name: sort_direction, first_name: sort_direction)
    else
      scope.order(sort_column => sort_direction)
    end
  end
end
