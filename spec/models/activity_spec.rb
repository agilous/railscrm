require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'associations' do
    it { should belong_to(:contact) }
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:activity_type) }
    it { should validate_presence_of(:title) }

    describe 'activity_type inclusion' do
      it 'validates activity_type is in ACTIVITY_TYPES' do
        contact = create(:contact)
        activity = build(:activity, contact: contact, activity_type: 'Call')
        expect(activity).to be_valid

        activity.activity_type = 'InvalidType'
        expect(activity).not_to be_valid
        expect(activity.errors[:activity_type]).to include('is not included in the list')
      end
    end

    describe 'priority inclusion' do
      it 'allows valid priority values' do
        contact = create(:contact)
        %w[Low Medium High].each do |priority|
          activity = build(:activity, contact: contact, priority: priority)
          expect(activity).to be_valid
        end
      end

      it 'allows blank priority' do
        contact = create(:contact)
        activity = build(:activity, contact: contact, priority: nil)
        expect(activity).to be_valid
      end

      it 'rejects invalid priority values' do
        contact = create(:contact)
        activity = build(:activity, contact: contact, priority: 'Invalid')
        expect(activity).not_to be_valid
        expect(activity.errors[:priority]).to include('is not included in the list')
      end
    end
  end

  describe 'constants' do
    it 'has predefined activity types' do
      expect(Activity::ACTIVITY_TYPES).to eq([ "Call", "Meeting", "Lunch", "Coffee", "Demo", "Presentation" ])
    end

    it 'has predefined priority levels' do
      expect(Activity::PRIORITY_LEVELS).to eq([ "Low", "Medium", "High" ])
    end
  end

  describe 'scopes' do
    let(:contact) { create(:contact) }
    let(:completed_activity) { create(:activity, contact: contact, completed_at: 1.day.ago) }
    let(:pending_activity) { create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now) }
    let(:overdue_activity) { create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago) }

    describe '.completed' do
      it 'returns only completed activities' do
        completed_activity
        pending_activity
        expect(Activity.completed).to include(completed_activity)
        expect(Activity.completed).not_to include(pending_activity)
      end
    end

    describe '.pending' do
      it 'returns only pending activities' do
        completed_activity
        pending_activity
        expect(Activity.pending).to include(pending_activity)
        expect(Activity.pending).not_to include(completed_activity)
      end
    end

    describe '.overdue' do
      it 'returns pending activities past due date' do
        pending_activity
        overdue_activity
        expect(Activity.overdue).to include(overdue_activity)
        expect(Activity.overdue).not_to include(pending_activity)
      end
    end

    describe '.upcoming' do
      it 'returns pending activities with future due date' do
        pending_activity
        overdue_activity
        expect(Activity.upcoming).to include(pending_activity)
        expect(Activity.upcoming).not_to include(overdue_activity)
      end
    end

    describe '.recent' do
      it 'returns activities ordered by creation date descending' do
        older = create(:activity, contact: contact, created_at: 2.days.ago)
        newer = create(:activity, contact: contact, created_at: 1.day.ago)
        expect(Activity.recent.first).to eq(newer)
        expect(Activity.recent.last).to eq(older)
      end
    end
  end

  describe 'instance methods' do
    let(:contact) { create(:contact) }

    describe '#completed?' do
      it 'returns true when completed_at is present' do
        activity = create(:activity, contact: contact, completed_at: Time.current)
        expect(activity.completed?).to be true
      end

      it 'returns false when completed_at is nil' do
        activity = create(:activity, contact: contact, completed_at: nil)
        expect(activity.completed?).to be false
      end
    end

    describe '#overdue?' do
      it 'returns true when activity is pending and due_date is in the past' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago)
        expect(activity.overdue?).to be true
      end

      it 'returns false when activity is completed' do
        activity = create(:activity, contact: contact, completed_at: Time.current, due_date: 1.day.ago)
        expect(activity.overdue?).to be false
      end

      it 'returns false when due_date is in the future' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now)
        expect(activity.overdue?).to be false
      end

      it 'returns false when due_date is nil' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: nil)
        expect(activity.overdue?).to be false
      end
    end

    describe '#status' do
      it 'returns "Completed" when activity is completed' do
        activity = create(:activity, contact: contact, completed_at: Time.current)
        expect(activity.status).to eq('Completed')
      end

      it 'returns "Overdue" when activity is overdue' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago)
        expect(activity.status).to eq('Overdue')
      end

      it 'returns "Scheduled" when activity is pending and not overdue' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now)
        expect(activity.status).to eq('Scheduled')
      end

      it 'returns "Scheduled" when activity has no due_date' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: nil)
        expect(activity.status).to eq('Scheduled')
      end
    end

    describe '#status_color' do
      it 'returns "green" for completed activities' do
        activity = create(:activity, contact: contact, completed_at: Time.current)
        expect(activity.status_color).to eq('green')
      end

      it 'returns "red" for overdue activities' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.ago)
        expect(activity.status_color).to eq('red')
      end

      it 'returns "blue" for scheduled activities' do
        activity = create(:activity, contact: contact, completed_at: nil, due_date: 1.day.from_now)
        expect(activity.status_color).to eq('blue')
      end
    end
  end
end
