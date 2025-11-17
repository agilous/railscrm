require 'rails_helper'

RSpec.describe PipedriveSync, type: :integration do
  let(:sync) { PipedriveSync.new }

  # Sample data from actual Pipedrive API responses
  let(:pipedrive_user) do
    {
      "id" => 1234,
      "name" => "Bill Barnett",
      "email" => "bill@launchscout.com",
      "phone" => "555-1234",
      "active_flag" => true
    }
  end

  let(:pipedrive_organization) do
    {
      "id" => 5678,
      "name" => "Busken Industries",
      "address" => "123 Main St",
      "cc_email" => "www.busken.com",
      "add_time" => "2024-01-01 10:00:00",
      "update_time" => "2024-01-01 10:00:00",
      "owner_id" => 1234
    }
  end

  let(:pipedrive_person_contact) do
    {
      "id" => 18822,
      "name" => "Dan Busken",
      "first_name" => "Dan",
      "last_name" => "Busken",
      "email" => [ { "value" => "dan@busken.com", "primary" => true } ],
      "phone" => [ { "value" => "555-5678", "primary" => true } ],
      "org_id" => 5678,
      "owner_id" => 1234,
      "open_deals_count" => 1,
      "closed_deals_count" => 0,
      "activities_count" => 2,
      "add_time" => "2025-09-26 10:00:00",
      "update_time" => "2025-09-26 10:00:00"
    }
  end

  let(:pipedrive_person_lead) do
    {
      "id" => 18823,
      "name" => "Jane Smith",
      "first_name" => "Jane",
      "last_name" => "Smith",
      "email" => [ { "value" => "jane@example.com", "primary" => true } ],
      "phone" => [ { "value" => "555-9999", "primary" => true } ],
      "org_id" => nil,
      "owner_id" => 1234,
      "open_deals_count" => 0,
      "closed_deals_count" => 0,
      "activities_count" => 0,
      "add_time" => "2025-09-27 10:00:00",
      "update_time" => "2025-09-27 10:00:00"
    }
  end

  let(:pipedrive_deal) do
    {
      "id" => 9999,
      "title" => "Enterprise Plan - Busken Industries",
      "value" => 50000,
      "person_id" => 18822,
      "org_id" => 5678,
      "owner_id" => 1234,
      "stage_id" => 1,
      "status" => "open",
      "expected_close_date" => "2024-12-31",
      "probability" => 80,
      "add_time" => "2024-01-15 10:00:00",
      "update_time" => "2024-01-15 10:00:00"
    }
  end

  let(:pipedrive_activity) do
    {
      "id" => 7777,
      "subject" => "Demo Meeting",
      "type" => "meeting",
      "note" => "Product demonstration for enterprise features",
      "due_date" => "2024-02-01",
      "due_time" => "14:00",
      "done" => false,
      "person_id" => 18822,
      "org_id" => 5678,
      "deal_id" => 9999,
      "add_time" => "2024-01-20 10:00:00",
      "update_time" => "2024-01-20 10:00:00"
    }
  end

  let(:pipedrive_note_for_contact) do
    {
      "id" => 1111,
      "content" => "Discussed potential partnership opportunities. Dan is interested in our enterprise solution.",
      "person_id" => 18822,
      "org_id" => nil,
      "deal_id" => nil,
      "add_time" => "2024-01-10 10:00:00",
      "update_time" => "2024-01-10 10:00:00"
    }
  end

  let(:pipedrive_note_for_deal) do
    {
      "id" => 2222,
      "content" => "Agreed on pricing structure for enterprise plan.",
      "person_id" => nil,
      "org_id" => nil,
      "deal_id" => 9999,
      "add_time" => "2024-01-16 10:00:00",
      "update_time" => "2024-01-16 10:00:00"
    }
  end

  let(:pipedrive_note_for_organization) do
    {
      "id" => 3333,
      "content" => "Company is expanding rapidly, good growth potential.",
      "person_id" => nil,
      "org_id" => 5678,
      "deal_id" => nil,
      "add_time" => "2024-01-05 10:00:00",
      "update_time" => "2024-01-05 10:00:00"
    }
  end

  describe "User sync" do
    it "creates a new user from Pipedrive data" do
      expect {
        sync.send(:sync_user, pipedrive_user)
      }.to change(User, :count).by(1)

      user = User.find_by(email: "bill@launchscout.com")
      expect(user).to be_present
      expect(user.first_name).to eq("Bill")
      expect(user.last_name).to eq("Barnett")
      expect(user.phone).to eq("555-1234")
      expect(user.approved).to be true
    end

    it "creates a PipedriveMapping for the user" do
      sync.send(:sync_user, pipedrive_user)

      mapping = PipedriveMapping.find_by(
        pipedrive_type: "User",
        pipedrive_id: 1234
      )
      expect(mapping).to be_present
      expect(mapping.rails_id).to eq(User.find_by(email: "bill@launchscout.com").id)
    end
  end

  describe "Organization sync" do
    before do
      sync.send(:sync_user, pipedrive_user)
    end

    it "creates an Account from Pipedrive Organization" do
      expect {
        sync.send(:sync_organization, pipedrive_organization)
      }.to change(Account, :count).by(1)

      account = Account.find_by(name: "Busken Industries")
      expect(account).to be_present
      expect(account.website).to eq("www.busken.com")
      expect(account.address).to eq("123 Main St")
    end

    it "creates a PipedriveMapping for the organization" do
      sync.send(:sync_organization, pipedrive_organization)

      mapping = PipedriveMapping.find_by(
        pipedrive_type: "Organization",
        pipedrive_id: 5678
      )
      expect(mapping).to be_present
    end
  end

  describe "Person sync" do
    before do
      sync.send(:sync_user, pipedrive_user)
      sync.send(:sync_organization, pipedrive_organization)
    end

    context "when person has deals (should be Contact)" do
      it "creates a Contact" do
        expect {
          sync.send(:sync_person, pipedrive_person_contact)
        }.to change(Contact, :count).by(1)

        contact = Contact.find_by(email: "dan@busken.com")
        expect(contact).to be_present
        expect(contact.first_name).to eq("Dan")
        expect(contact.last_name).to eq("Busken")
        expect(contact.phone).to eq("555-5678")
        expect(contact.company).to eq("Busken Industries")
      end

      it "creates a Contact PipedriveMapping" do
        sync.send(:sync_person, pipedrive_person_contact)

        mapping = PipedriveMapping.find_by(
          pipedrive_type: "Contact",
          pipedrive_id: 18822
        )
        expect(mapping).to be_present
        expect(mapping.rails_id).to eq(Contact.find_by(email: "dan@busken.com").id)
      end
    end

    context "when person has no deals (should be Lead)" do
      it "creates a Lead" do
        expect {
          sync.send(:sync_person, pipedrive_person_lead)
        }.to change(Lead, :count).by(1)

        lead = Lead.find_by(email: "jane@example.com")
        expect(lead).to be_present
        expect(lead.first_name).to eq("Jane")
        expect(lead.last_name).to eq("Smith")
        expect(lead.lead_status).to eq("new")
      end

      it "creates a Lead PipedriveMapping" do
        sync.send(:sync_person, pipedrive_person_lead)

        mapping = PipedriveMapping.find_by(
          pipedrive_type: "Lead",
          pipedrive_id: 18823
        )
        expect(mapping).to be_present
      end
    end
  end

  describe "Deal sync" do
    before do
      sync.send(:sync_user, pipedrive_user)
      sync.send(:sync_organization, pipedrive_organization)
      sync.send(:sync_person, pipedrive_person_contact)
    end

    it "creates an Opportunity" do
      expect {
        sync.send(:sync_deal, pipedrive_deal)
      }.to change(Opportunity, :count).by(1)

      opportunity = Opportunity.find_by(opportunity_name: "Enterprise Plan - Busken Industries")
      expect(opportunity).to be_present
      expect(opportunity.amount).to eq(50000)
      expect(opportunity.account_name).to eq("Busken Industries")
      expect(opportunity.probability).to eq(80)
    end

    it "creates an Opportunity PipedriveMapping" do
      sync.send(:sync_deal, pipedrive_deal)

      mapping = PipedriveMapping.find_by(
        pipedrive_type: "Opportunity",
        pipedrive_id: 9999
      )
      expect(mapping).to be_present
    end
  end

  describe "Activity sync" do
    before do
      # Create default user
      User.create!(
        email: "admin@example.com",
        password: "password123",
        first_name: "Admin",
        last_name: "User",
        admin: true,
        approved: true
      )
    end

    it "creates a Task" do
      expect {
        sync.send(:sync_activity, pipedrive_activity)
      }.to change(Task, :count).by(1)

      task = Task.find_by(title: "Demo Meeting")
      expect(task).to be_present
      expect(task.description).to include("Product demonstration")
      expect(task.completed).to be false
    end

    it "creates a Task PipedriveMapping" do
      sync.send(:sync_activity, pipedrive_activity)

      mapping = PipedriveMapping.find_by(
        pipedrive_type: "Task",
        pipedrive_id: 7777
      )
      expect(mapping).to be_present
    end
  end

  describe "Note sync" do
    before do
      # Set up all the entities
      sync.send(:sync_user, pipedrive_user)
      sync.send(:sync_organization, pipedrive_organization)
      sync.send(:sync_person, pipedrive_person_contact)
      sync.send(:sync_person, pipedrive_person_lead)
      sync.send(:sync_deal, pipedrive_deal)
    end

    context "when note is for a Contact" do
      it "attaches the note to the Contact" do
        expect {
          sync.send(:sync_note, pipedrive_note_for_contact)
        }.to change(Note, :count).by(1)

        contact = Contact.find_by(email: "dan@busken.com")
        expect(contact.notes.count).to eq(1)

        note = contact.notes.first
        expect(note.content).to include("Discussed potential partnership")
      end

      it "creates a Note PipedriveMapping" do
        sync.send(:sync_note, pipedrive_note_for_contact)

        mapping = PipedriveMapping.find_by(
          pipedrive_type: "Note",
          pipedrive_id: 1111
        )
        expect(mapping).to be_present
      end
    end

    context "when note is for a Deal/Opportunity" do
      it "attaches the note to the Opportunity" do
        expect {
          sync.send(:sync_note, pipedrive_note_for_deal)
        }.to change(Note, :count).by(1)

        opportunity = Opportunity.find_by(opportunity_name: "Enterprise Plan - Busken Industries")
        expect(opportunity.notes.count).to eq(1)

        note = opportunity.notes.first
        expect(note.content).to include("Agreed on pricing structure")
      end
    end

    context "when note is for an Organization/Account" do
      it "attaches the note to the Account" do
        expect {
          sync.send(:sync_note, pipedrive_note_for_organization)
        }.to change(Note, :count).by(1)

        account = Account.find_by(name: "Busken Industries")
        expect(account.notes.count).to eq(1)

        note = account.notes.first
        expect(note.content).to include("Company is expanding rapidly")
      end
    end
  end

  describe "find_notable_for_note method" do
    before do
      sync.send(:sync_user, pipedrive_user)
      sync.send(:sync_organization, pipedrive_organization)
      sync.send(:sync_person, pipedrive_person_contact)
      sync.send(:sync_person, pipedrive_person_lead)
      sync.send(:sync_deal, pipedrive_deal)
    end

    it "finds Contact for person_id when Contact mapping exists" do
      note = { "person_id" => 18822, "org_id" => nil, "deal_id" => nil }
      notable = sync.send(:find_notable_for_note, note)

      expect(notable).to be_a(Contact)
      expect(notable.email).to eq("dan@busken.com")
    end

    it "finds Lead for person_id when Lead mapping exists" do
      note = { "person_id" => 18823, "org_id" => nil, "deal_id" => nil }
      notable = sync.send(:find_notable_for_note, note)

      expect(notable).to be_a(Lead)
      expect(notable.email).to eq("jane@example.com")
    end

    it "finds Opportunity for deal_id" do
      note = { "person_id" => nil, "org_id" => nil, "deal_id" => 9999 }
      notable = sync.send(:find_notable_for_note, note)

      expect(notable).to be_a(Opportunity)
      expect(notable.opportunity_name).to eq("Enterprise Plan - Busken Industries")
    end

    it "finds Account for org_id" do
      note = { "person_id" => nil, "org_id" => 5678, "deal_id" => nil }
      notable = sync.send(:find_notable_for_note, note)

      expect(notable).to be_a(Account)
      expect(notable.name).to eq("Busken Industries")
    end
  end

  describe "Full sync integration" do
    it "properly links all relationships" do
      # Sync in proper order
      sync.send(:sync_user, pipedrive_user)
      sync.send(:sync_organization, pipedrive_organization)
      sync.send(:sync_person, pipedrive_person_contact)
      sync.send(:sync_deal, pipedrive_deal)
      sync.send(:sync_activity, pipedrive_activity)
      sync.send(:sync_note, pipedrive_note_for_contact)
      sync.send(:sync_note, pipedrive_note_for_deal)
      sync.send(:sync_note, pipedrive_note_for_organization)

      # Verify Contact relationships
      contact = Contact.find_by(email: "dan@busken.com")
      expect(contact).to be_present
      expect(contact.notes.count).to eq(1)
      expect(contact.deals.count).to eq(1)
      expect(contact.company).to eq("Busken Industries")

      # Verify Opportunity relationships
      opportunity = contact.deals.first
      expect(opportunity.notes.count).to eq(1)
      expect(opportunity.account_name).to eq("Busken Industries")

      # Verify Account relationships
      account = Account.find_by(name: "Busken Industries")
      expect(account.notes.count).to eq(1)

      # Verify all PipedriveMappings exist
      expect(PipedriveMapping.count).to eq(8) # user, org, 2 persons, deal, activity, 3 notes
    end
  end
end
