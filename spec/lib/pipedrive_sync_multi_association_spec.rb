require 'rails_helper'

RSpec.describe "PipedriveSync Multi-Association Notes", type: :integration do
  let(:sync) { PipedriveSync.new }

  before do
    # Create base entities
    sync.send(:sync_user, {
      "id" => 1234,
      "name" => "Test User",
      "email" => "test@example.com",
      "active_flag" => true
    })

    sync.send(:sync_organization, {
      "id" => 5678,
      "name" => "Test Company",
      "add_time" => "2024-01-01 10:00:00"
    })

    sync.send(:sync_person, {
      "id" => 18822,
      "name" => "Test Person",
      "first_name" => "Test",
      "last_name" => "Person",
      "email" => [ { "value" => "test.person@example.com", "primary" => true } ],
      "org_id" => 5678,
      "open_deals_count" => 1,
      "add_time" => "2024-01-01 10:00:00"
    })

    sync.send(:sync_deal, {
      "id" => 9999,
      "title" => "Test Deal",
      "value" => 10000,
      "person_id" => 18822,
      "org_id" => 5678,
      "owner_id" => 1234,
      "status" => "open",
      "add_time" => "2024-01-01 10:00:00"
    })
  end

  describe "sync_note with multiple associations" do
    context "when note has both person_id and deal_id" do
      let(:pipedrive_note) do
        {
          "id" => 1111,
          "content" => "Note attached to both person and deal",
          "person_id" => 18822,
          "deal_id" => 9999,
          "org_id" => nil,
          "add_time" => "2024-01-10 10:00:00"
        }
      end

      it "creates note with associations to both Contact and Opportunity" do
        expect {
          sync.send(:sync_note, pipedrive_note)
        }.to change(Note, :count).by(1)

        note = Note.find_by(content: "Note attached to both person and deal")
        expect(note).to be_present

        # Check associations
        contact = Contact.find_by(email: "test.person@example.com")
        opportunity = Opportunity.find_by(opportunity_name: "Test Deal")

        expect(note.all_notables).to include(contact, opportunity)
        expect(note.note_associations.count).to eq(2)

        # Verify note appears in both entities' collections
        expect(contact.notes).to include(note)
        expect(opportunity.notes).to include(note)
      end
    end

    context "when note has person_id, deal_id, and org_id" do
      let(:pipedrive_note) do
        {
          "id" => 2222,
          "content" => "Note attached to all three entities",
          "person_id" => 18822,
          "deal_id" => 9999,
          "org_id" => 5678,
          "add_time" => "2024-01-10 10:00:00"
        }
      end

      it "creates note with associations to Contact, Opportunity, and Account" do
        expect {
          sync.send(:sync_note, pipedrive_note)
        }.to change(Note, :count).by(1)

        note = Note.find_by(content: "Note attached to all three entities")

        contact = Contact.find_by(email: "test.person@example.com")
        opportunity = Opportunity.find_by(opportunity_name: "Test Deal")
        account = Account.find_by(name: "Test Company")

        expect(note.all_notables).to contain_exactly(opportunity, contact, account)
        expect(note.note_associations.count).to eq(3)

        # Verify visibility from all entities
        expect(contact.notes).to include(note)
        expect(opportunity.notes).to include(note)
        expect(account.notes).to include(note)
      end
    end

    context "when note already exists" do
      let(:pipedrive_note) do
        {
          "id" => 3333,
          "content" => "Existing note content",
          "person_id" => 18822,
          "deal_id" => 9999,
          "org_id" => nil
        }
      end

      it "adds associations to existing note without duplicating" do
        # Create the existing note first
        existing_note = Note.create!(content: "Existing note content")

        expect {
          sync.send(:sync_note, pipedrive_note)
        }.not_to change(Note, :count)

        existing_note.reload
        expect(existing_note.note_associations.count).to eq(2)

        contact = Contact.find_by(email: "test.person@example.com")
        opportunity = Opportunity.find_by(opportunity_name: "Test Deal")

        expect(existing_note.all_notables).to include(contact, opportunity)
      end
    end

    context "when note has only person_id" do
      let(:pipedrive_note) do
        {
          "id" => 4444,
          "content" => "Note only for person",
          "person_id" => 18822,
          "deal_id" => nil,
          "org_id" => nil
        }
      end

      it "creates note with single association to Contact" do
        sync.send(:sync_note, pipedrive_note)

        note = Note.find_by(content: "Note only for person")
        contact = Contact.find_by(email: "test.person@example.com")

        expect(note.all_notables).to eq([ contact ])
        expect(note.note_associations.count).to eq(1)
      end
    end
  end

  describe "find_all_notables_for_note" do
    let(:contact) { Contact.find_by(email: "test.person@example.com") }
    let(:opportunity) { Opportunity.find_by(opportunity_name: "Test Deal") }
    let(:account) { Account.find_by(name: "Test Company") }

    it "returns all applicable notables for a note" do
      note_data = {
        "person_id" => 18822,
        "deal_id" => 9999,
        "org_id" => 5678
      }

      notables = sync.send(:find_all_notables_for_note, note_data)

      expect(notables).to contain_exactly(opportunity, contact, account)
    end

    it "returns empty array when no entities found" do
      note_data = {
        "person_id" => 99999,
        "deal_id" => 88888,
        "org_id" => 77777
      }

      notables = sync.send(:find_all_notables_for_note, note_data)

      expect(notables).to be_empty
    end

    it "handles nil IDs gracefully" do
      note_data = {
        "person_id" => nil,
        "deal_id" => nil,
        "org_id" => nil
      }

      notables = sync.send(:find_all_notables_for_note, note_data)

      expect(notables).to be_empty
    end
  end
end
