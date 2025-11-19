require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'associations' do
    it { should belong_to(:contact) }
  end

  describe 'validations' do
    it { should validate_presence_of(:activity_type) }
    it { should validate_presence_of(:title) }
  end

  describe 'constants' do
    it 'has predefined activity types' do
      expect(Activity::ACTIVITY_TYPES).to eq([ "Call", "Meeting", "Lunch", "Coffee", "Demo", "Presentation" ])
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
end
