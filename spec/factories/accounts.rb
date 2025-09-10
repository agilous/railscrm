FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    sequence(:email) { |n| "account#{n}@example.com" }
    website { "http://example.com" }
    phone { "555-0400" }
    address { "789 Business Blvd" }
    city { "Business City" }
    state { "TX" }
    zip { "73301" }
  end
end
