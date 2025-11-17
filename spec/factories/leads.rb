FactoryBot.define do
  factory :lead do
    association :assigned_to, factory: :user
    sequence(:email) { |n| "lead#{n}@example.com" }
    sequence(:first_name) { |n| "Lead#{n}" }
    last_name { "Johnson" }
    company { "Lead Company" }
    phone { "555-0300" }
    address { "456 Oak Ave" }
    city { "Lead City" }
    state { "CA" }
    zip { "90210" }
    lead_owner { "Test Owner" }
    lead_status { "new" }
    lead_source { "web" }
    interested_in { "web_app" }
    comments { "Test lead comments" }

    trait :contacted do
      lead_status { "contacted" }
    end

    trait :qualified do
      lead_status { "qualified" }
    end

    trait :disqualified do
      lead_status { "disqualified" }
    end

    trait :from_phone do
      lead_source { "phone" }
    end

    trait :from_referral do
      lead_source { "referral" }
    end

    trait :interested_in_ios do
      interested_in { "ios" }
    end

    trait :with_notes do
      transient do
        notes_count { 2 }
      end

      after(:create) do |lead, evaluator|
        evaluator.notes_count.times do
          note = create(:note)
          note.add_notable(lead)
        end
      end
    end
  end
end
