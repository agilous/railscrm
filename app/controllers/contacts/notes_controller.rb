class Contacts::NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact

  def create
    @note = Note.new(note_params)
    @note.user = current_user

    # Add contact association using multi-association system
    @note.note_associations.build(notable: @contact)

    respond_to do |format|
      if @note.save
        format.html { redirect_to @contact, notice: "Note was successfully added." }
        format.json { render json: @note, status: :created }
      else
        format.html { redirect_to @contact, alert: "Failed to add note." }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
