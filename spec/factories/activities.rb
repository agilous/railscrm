FactoryBot.define do
  factory :activity do
    contact { nil }
    activity_type { "MyString" }
    title { "MyString" }
    description { "MyText" }
    completed_at { "2025-11-08 17:48:37" }
    due_date { "2025-11-08 17:48:37" }
  end
end
