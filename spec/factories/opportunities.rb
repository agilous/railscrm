FactoryBot.define do
  factory :opportunity do
    sequence(:opportunity_name) { |n| "Opportunity #{n}" }
    sequence(:account_name) { |n| "Account #{n}" }
    amount { 10000.00 }
    stage { "prospecting" }
    owner { "Sales Rep" }
    probability { 25 }
    closing_date { 30.days.from_now.to_date }
    contact_name { "Contact Name" }
    type { "new_customer" }
    comments { "Test opportunity description" }

    trait :proposal_stage do
      stage { "proposal" }
      probability { 50 }
    end

    trait :negotiation_stage do
      stage { "negotiation" }
      probability { 75 }
    end

    trait :closed_won do
      stage { "closed_won" }
      probability { 100 }
    end

    trait :closed_lost do
      stage { "closed_lost" }
      probability { 0 }
    end

    trait :existing_customer do
      type { "existing_customer" }
    end

    trait :large_deal do
      amount { 100000.00 }
    end
  end
end
