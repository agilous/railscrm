FactoryBot.define do
  factory :contact do
    sequence(:email) { |n| "contact#{n}@example.com" }
    sequence(:first_name) { |n| "Contact#{n}" }
    last_name { "Smith" }
    company { "Contact Company" }
    phone { "555-0200" }
    address { "123 Main St" }
    city { "Anytown" }
    state { "NY" }
    zip { "12345" }
  end
end
