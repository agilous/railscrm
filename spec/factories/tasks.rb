FactoryBot.define do
  factory :task do
    association :assignee, factory: :user
    sequence(:title) { |n| "Task #{n}" }
    description { "This is a test task that needs to be completed." }
    due_date { 1.week.from_now }
    completed { false }
    priority { "medium" }

    trait :completed do
      completed { true }
    end

    trait :pending do
      completed { false }
    end

    trait :overdue do
      due_date { 1.week.ago }
      completed { false }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :low_priority do
      priority { "low" }
    end

    trait :due_today do
      due_date { Date.current }
    end

    trait :no_description do
      description { nil }
    end
  end
end
