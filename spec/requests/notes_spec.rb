require 'rails_helper'

RSpec.describe "Notes", type: :request do
  let(:user) { create(:approved_user) }
  let(:other_user) { create(:approved_user) }
  let(:contact) { create(:contact) }
  let(:account) { create(:account) }
  let(:opportunity) { create(:opportunity) }
  let(:lead) { create(:lead) }

  before do
    sign_in user
  end

  describe "POST /notes" do
    context "with valid params" do
      it "creates a new note with a single association" do
        expect {
          post notes_path, params: {
            note: {
              content: "Test note content",
              notable_ids: [ "Contact-#{contact.id}" ]
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.content).to eq("Test note content")
        expect(note.user).to eq(user)
        expect(note.note_associations.count).to eq(1)
        expect(note.contacts).to include(contact)
      end

      it "creates a note with multiple associations" do
        expect {
          post notes_path, params: {
            note: {
              content: "Multi-association note",
              notable_ids: [
                "Contact-#{contact.id}",
                "Account-#{account.id}",
                "Opportunity-#{opportunity.id}"
              ]
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.note_associations.count).to eq(3)
        expect(note.contacts).to include(contact)
        expect(note.accounts).to include(account)
        expect(note.opportunities).to include(opportunity)
      end

      it "handles empty notable_ids" do
        expect {
          post notes_path, params: {
            note: {
              content: "Note without associations",
              notable_ids: []
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.content).to eq("Note without associations")
        expect(note.note_associations.count).to eq(0)
      end

      it "ignores blank notable_ids" do
        expect {
          post notes_path, params: {
            note: {
              content: "Note with blank ids",
              notable_ids: [ "", "Contact-#{contact.id}", "" ]
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.note_associations.count).to eq(1)
        expect(note.contacts).to include(contact)
      end

      it "redirects back after successful creation" do
        post notes_path, params: {
          note: {
            content: "Test note",
            notable_ids: [ "Contact-#{contact.id}" ]
          }
        }, headers: { "HTTP_REFERER" => contact_path(contact) }

        expect(response).to redirect_to(contact_path(contact))
        follow_redirect!
        expect(response.body).to include("Note was successfully created")
      end

      it "returns JSON when requested" do
        post notes_path, params: {
          note: {
            content: "API note",
            notable_ids: [ "Contact-#{contact.id}" ]
          }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["content"]).to eq("API note")
      end
    end

    context "with invalid params" do
      it "fails without content" do
        expect {
          post notes_path, params: {
            note: {
              content: "",
              notable_ids: [ "Contact-#{contact.id}" ]
            }
          }
        }.not_to change(Note, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Failed to create note.")
      end

      it "ignores non-existent notable IDs" do
        expect {
          post notes_path, params: {
            note: {
              content: "Note with non-existent IDs",
              notable_ids: [ "Contact-99999", "Account-88888" ]
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.note_associations.count).to eq(0)
      end

      it "ignores invalid notable types" do
        expect {
          post notes_path, params: {
            note: {
              content: "Note with invalid type",
              notable_ids: [ "InvalidType-1", "Contact-#{contact.id}" ]
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.note_associations.count).to eq(1)
        expect(note.contacts).to include(contact)
      end

      it "skips records owned by other users" do
        my_lead = create(:lead, assigned_to: user)
        other_lead = create(:lead, assigned_to: other_user)

        expect {
          post notes_path, params: {
            note: {
              content: "Note trying to access other user's records",
              notable_ids: [
                "Contact-#{contact.id}",
                "Lead-#{my_lead.id}",
                "Lead-#{other_lead.id}"
              ]
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        # Contact and my_lead should be associated, but not other_lead
        expect(note.note_associations.count).to eq(2)
        expect(note.contacts).to include(contact)
        expect(note.leads).to include(my_lead)
        expect(note.leads).not_to include(other_lead)
      end

      it "returns JSON error when requested" do
        post notes_path, params: {
          note: {
            content: "",
            notable_ids: [ "Contact-#{contact.id}" ]
          }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["content"]).to include("can't be blank")
      end
    end

    context "from nested routes" do
      it "creates a note from lead nested route" do
        expect {
          post lead_notes_path(lead), params: {
            note: {
              content: "Lead note"
            }
          }
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.leads).to include(lead)
      end
    end
  end

  describe "authentication" do
    it "requires authentication" do
      sign_out user

      post notes_path, params: {
        note: { content: "Test" }
      }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
