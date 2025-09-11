require 'rails_helper'

RSpec.describe PipedriveMapping, type: :model do
  describe 'validations' do
    subject(:mapping) { build(:pipedrive_mapping) }

    it { is_expected.to validate_presence_of(:pipedrive_type) }
    it { is_expected.to validate_presence_of(:pipedrive_id) }
    it { is_expected.to validate_presence_of(:rails_id) }

    describe 'uniqueness validation' do
      let!(:existing_mapping) do
        create(:pipedrive_mapping,
               pipedrive_type: 'person',
               pipedrive_id: 123,
               rails_id: 456)
      end

      it 'validates uniqueness of pipedrive_id scoped to pipedrive_type' do
        duplicate_mapping = build(:pipedrive_mapping,
                                  pipedrive_type: 'person',
                                  pipedrive_id: 123,
                                  rails_id: 789)

        expect(duplicate_mapping).not_to be_valid
        expect(duplicate_mapping.errors[:pipedrive_id]).to include('has already been taken')
      end

      it 'allows same pipedrive_id for different pipedrive_types' do
        different_type_mapping = build(:pipedrive_mapping,
                                       pipedrive_type: 'organization',
                                       pipedrive_id: 123,
                                       rails_id: 789)

        expect(different_type_mapping).to be_valid
      end

      it 'allows different pipedrive_id for same pipedrive_type' do
        different_id_mapping = build(:pipedrive_mapping,
                                     pipedrive_type: 'person',
                                     pipedrive_id: 124,
                                     rails_id: 789)

        expect(different_id_mapping).to be_valid
      end
    end
  end

  describe 'database constraints' do
    let!(:existing_mapping) do
      create(:pipedrive_mapping,
             pipedrive_type: 'person',
             pipedrive_id: 123,
             rails_id: 456)
    end

    it 'enforces unique index on pipedrive_type and pipedrive_id combination' do
      expect {
        PipedriveMapping.create!(
          pipedrive_type: 'person',
          pipedrive_id: 123,
          rails_id: 789
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'factory' do
    it 'creates a valid pipedrive mapping' do
      mapping = build(:pipedrive_mapping)
      expect(mapping).to be_valid
    end

    it 'has required attributes' do
      mapping = create(:pipedrive_mapping)

      expect(mapping.pipedrive_type).to be_present
      expect(mapping.pipedrive_id).to be_present
      expect(mapping.rails_id).to be_present
      expect(mapping.created_at).to be_present
      expect(mapping.updated_at).to be_present
    end
  end

  describe 'common use cases' do
    it 'can store mappings for different entity types' do
      person_mapping = create(:pipedrive_mapping, pipedrive_type: 'person', pipedrive_id: 1, rails_id: 100)
      org_mapping = create(:pipedrive_mapping, pipedrive_type: 'organization', pipedrive_id: 1, rails_id: 200)
      deal_mapping = create(:pipedrive_mapping, pipedrive_type: 'deal', pipedrive_id: 1, rails_id: 300)

      expect(person_mapping).to be_valid
      expect(org_mapping).to be_valid
      expect(deal_mapping).to be_valid
    end

    it 'can find mapping by pipedrive entity' do
      mapping = create(:pipedrive_mapping, pipedrive_type: 'person', pipedrive_id: 123, rails_id: 456)

      found_mapping = PipedriveMapping.find_by(pipedrive_type: 'person', pipedrive_id: 123)
      expect(found_mapping).to eq(mapping)
      expect(found_mapping.rails_id).to eq(456)
    end
  end
end
