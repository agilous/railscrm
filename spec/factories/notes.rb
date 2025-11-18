FactoryBot.define do
  factory :note do
    content { "This is a test note with important information." }

    # Notes no longer require a direct notable association due to the new multi-association system
    # Use traits to add associations after creation if needed

    trait :with_lead do
      after(:create) do |note|
        lead = create(:lead)
        note.add_notable(lead)
      end
    end

    trait :with_contact do
      after(:create) do |note|
        contact = create(:contact)
        note.add_notable(contact)
      end
    end

    trait :with_account do
      after(:create) do |note|
        account = create(:account)
        note.add_notable(account)
      end
    end

    trait :with_opportunity do
      after(:create) do |note|
        opportunity = create(:opportunity)
        note.add_notable(opportunity)
      end
    end

    trait :with_multiple_associations do
      after(:create) do |note|
        note.add_notable(create(:contact))
        note.add_notable(create(:opportunity))
        note.add_notable(create(:account))
      end
    end

    # Traits for tests that need specific association types
    trait :for_lead do
      # Empty trait - association is added in tests when needed
    end

    trait :for_contact do
      # Empty trait - association is added in tests when needed
    end

    trait :for_account do
      # Empty trait - association is added in tests when needed
    end

    trait :short do
      content { "Short note" }
    end

    trait :long do
      content { "This is a very long note with lots of details about the interaction, meeting notes, follow-up actions, and other important information that needs to be tracked." }
    end
  end
end
