class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notable, only: [ :new, :create ], if: -> { params[:lead_id].present? }

  def new
    @note = Note.new
    redirect_to :back
  end

  def create
    @note = Note.new(note_params)
    @note.user = current_user

    # Handle multi-associations from notable_ids parameter
    if params[:note][:notable_ids].present?
      params[:note][:notable_ids].each do |notable_string|
        next if notable_string.blank?

        # Parse format: "ModelName-id"
        parts = notable_string.split("-")
        notable_type = parts[0]
        notable_id = parts[1]

        if notable_type.present? && notable_id.present?
          # Validate that the notable type is a valid model and record exists
          begin
            klass = notable_type.constantize
            # Check if the record exists and user has access
            notable_record = klass.find_by(id: notable_id)

            if notable_record
              # Add authorization check based on model's user association
              case notable_type
              when "Lead"
                next if notable_record.assigned_to_id.present? && notable_record.assigned_to_id != current_user.id
              when "Task"
                next if notable_record.assignee_id.present? && notable_record.assignee_id != current_user.id
              end

              @note.note_associations.build(
                notable_type: notable_type,
                notable_id: notable_id
              )
            end
          rescue NameError
            # Skip invalid notable types
          end
        end
      end
    end

    # If called from nested route (e.g., /leads/:lead_id/notes)
    if @notable
      @note.note_associations.build(notable: @notable)
    end

    if @note.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: "Note was successfully created.") }
        format.json { render json: @note, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to create note.") }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_notable
    @notable = Lead.find(params[:lead_id]) if params[:lead_id]
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
