require 'rails_helper'

RSpec.describe "Model Relationships" do
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let(:contact) { create(:contact) }
  let(:lead) { create(:lead, assigned_to: user) }
  let(:opportunity) { create(:opportunity) }
  let(:task) { create(:task, assignee: user) }

  describe Contact do
    it { should have_many(:note_associations).dependent(:destroy) }
    it { should have_many(:notes).through(:note_associations) }
    it { should have_many(:activities).dependent(:destroy) }
    it { should have_many(:deals).class_name('Opportunity') }

    it "has notes through multi-association" do
      note = Note.create!(content: "Test note")
      note.add_notable(contact)
      expect(contact.notes).to include(note)
      expect(note.contacts).to include(contact)
    end

    it "has activities" do
      activity = Activity.create!(
        contact: contact,
        activity_type: "Call",
        title: "Follow-up call"
      )
      expect(contact.activities).to include(activity)
      expect(activity.contact).to eq(contact)
    end

    it "has deals through email relationship" do
      contact.update!(email: "test@example.com")
      opportunity.update!(contact_name: "test@example.com")
      expect(contact.deals).to include(opportunity)
    end
  end

  describe Lead do
    it { should have_many(:note_associations).dependent(:destroy) }
    it { should have_many(:notes).through(:note_associations) }
    it { should belong_to(:assigned_to).class_name('User') }

    it "has notes through multi-association" do
      note = Note.create!(content: "Lead note")
      note.add_notable(lead)
      expect(lead.notes).to include(note)
      expect(note.leads).to include(lead)
    end
  end

  describe Opportunity do
    it { should have_many(:note_associations).dependent(:destroy) }
    it { should have_many(:notes).through(:note_associations) }

    it "has notes through multi-association" do
      note = Note.create!(content: "Deal note")
      note.add_notable(opportunity)
      expect(opportunity.notes).to include(note)
      expect(note.opportunities).to include(opportunity)
    end

    it "belongs to contact through email" do
      contact.update!(email: "deal@example.com")
      opportunity.update!(contact_name: "deal@example.com")
      expect(opportunity.contact_name).to eq(contact.email)
      expect(contact.deals).to include(opportunity)
    end
  end

  describe Account do
    it { should have_many(:note_associations).dependent(:destroy) }
    it { should have_many(:notes).through(:note_associations) }

    it "has notes through multi-association" do
      note = Note.create!(content: "Account note")
      note.add_notable(account)
      expect(account.notes).to include(note)
      expect(note.accounts).to include(account)
    end
  end

  describe Note do
    it { should have_many(:note_associations).dependent(:destroy) }
    it { should have_many(:contacts).through(:note_associations) }
    it { should have_many(:leads).through(:note_associations) }
    it { should have_many(:accounts).through(:note_associations) }
    it { should have_many(:opportunities).through(:note_associations) }

    it "can belong to different notable types through associations" do
      contact_note = Note.create!(content: "Contact note")
      contact_note.add_notable(contact)

      lead_note = Note.create!(content: "Lead note")
      lead_note.add_notable(lead)

      account_note = Note.create!(content: "Account note")
      account_note.add_notable(account)

      opportunity_note = Note.create!(content: "Opportunity note")
      opportunity_note.add_notable(opportunity)

      expect(contact_note.contacts).to include(contact)
      expect(lead_note.leads).to include(lead)
      expect(account_note.accounts).to include(account)
      expect(opportunity_note.opportunities).to include(opportunity)
    end
  end

  describe Activity do
    it { should belong_to(:contact) }

    it "validates required fields" do
      activity = Activity.new
      expect(activity).not_to be_valid
      expect(activity.errors[:contact]).to include("must exist")
      expect(activity.errors[:activity_type]).to include("can't be blank")
      expect(activity.errors[:title]).to include("can't be blank")
    end

    it "has valid activity types" do
      Activity::ACTIVITY_TYPES.each do |type|
        activity = Activity.new(
          contact: contact,
          activity_type: type,
          title: "Test #{type}"
        )
        expect(activity).to be_valid
      end
    end
  end

  describe Task do
    it { should belong_to(:assignee).class_name('User') }

    it "has scopes" do
      completed_task = create(:task, assignee: user, completed: true)
      pending_task = create(:task, assignee: user, completed: false)
      overdue_task = create(:task, assignee: user, completed: false, due_date: 1.day.ago)
      upcoming_task = create(:task, assignee: user, completed: false, due_date: 1.day.from_now)

      expect(Task.completed).to include(completed_task)
      expect(Task.completed).not_to include(pending_task)

      expect(Task.pending).to include(pending_task, overdue_task, upcoming_task)
      expect(Task.pending).not_to include(completed_task)
    end
  end

  describe PipedriveMapping do
    it "stores mappings between Pipedrive and Rails records" do
      mapping = PipedriveMapping.create!(
        pipedrive_type: "Contact",
        pipedrive_id: 12345,
        rails_id: contact.id
      )

      expect(mapping.pipedrive_type).to eq("Contact")
      expect(mapping.pipedrive_id).to eq(12345)
      expect(mapping.rails_id).to eq(contact.id)
    end

    it "ensures unique pipedrive_id per type" do
      PipedriveMapping.create!(
        pipedrive_type: "Contact",
        pipedrive_id: 12345,
        rails_id: contact.id
      )

      duplicate = PipedriveMapping.new(
        pipedrive_type: "Contact",
        pipedrive_id: 12345,
        rails_id: contact.id + 1
      )

      expect(duplicate).not_to be_valid
    end
  end
end
