FactoryBot.define do
  factory :kanban_task do
    sequence(:name) { |n| "Task #{n}" }
    status { "to_do" }
    task_type { "rehearsal" }
    description { "Task description" }
    deadline { Date.today + 7.days }
    position { 0 }
    association :created_by, factory: :user

    trait :in_progress do
      status { "in_progress" }
    end

    trait :in_review do
      status { "review" }
    end

    trait :done do
      status { "done" }
    end

    trait :overdue do
      deadline { Date.today - 1.day }
      status { "to_do" }
    end

    trait :upcoming do
      deadline { Date.today + 3.days }
    end
  end
end
