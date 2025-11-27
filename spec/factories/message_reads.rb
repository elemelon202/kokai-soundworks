FactoryBot.define do
  factory :message_read do
    message
    user
    read { false }

    trait :read do
      read { true }
    end
  end
end
