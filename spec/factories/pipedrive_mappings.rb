FactoryBot.define do
  factory :pipedrive_mapping do
    pipedrive_type { 'person' }
    sequence(:pipedrive_id) { |n| n }
    sequence(:rails_id) { |n| n + 1000 }

    trait :person_mapping do
      pipedrive_type { 'person' }
    end

    trait :organization_mapping do
      pipedrive_type { 'organization' }
    end

    trait :deal_mapping do
      pipedrive_type { 'deal' }
    end

    trait :activity_mapping do
      pipedrive_type { 'activity' }
    end

    trait :note_mapping do
      pipedrive_type { 'note' }
    end

    trait :user_mapping do
      pipedrive_type { 'user' }
    end
  end
end
