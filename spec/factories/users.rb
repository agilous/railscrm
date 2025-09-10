FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "User#{n}" }
    last_name { "Doe" }
    company { "Test Company" }
    phone { "555-0100" }
    password { "password123" }
    password_confirmation { "password123" }
    approved { true }
    admin { false }

    trait :admin do
      admin { true }
    end

    trait :unapproved do
      approved { false }
    end

    trait :with_leads do
      transient do
        leads_count { 3 }
      end

      after(:create) do |user, evaluator|
        create_list(:lead, evaluator.leads_count, assigned_to: user)
      end
    end
  end
end
