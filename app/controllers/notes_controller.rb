class NotesController < ApplicationController
  before_action :authenticate_user!

  def new
    @lead = Lead.new
    redirect_to :back
  end


  def create
    @lead = Lead.find(params[:lead_id])
    @note = @lead.notes.create(note_params)
    redirect_to @lead
  end

  private

  def note_params
    params.require(:note).permit(:content)
  end
end
