FactoryBot.define do
  factory :note do
    content { "This is a test note with important information." }

    # Default to lead as notable, but can be overridden
    for_lead

    trait :for_lead do
      association :notable, factory: :lead
    end

    trait :for_contact do
      association :notable, factory: :contact
    end

    trait :for_account do
      association :notable, factory: :account
    end

    trait :short do
      content { "Short note" }
    end

    trait :long do
      content { "This is a very long note with lots of details about the interaction, meeting notes, follow-up actions, and other important information that needs to be tracked." }
    end
  end
end
