FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    user_type { "musician" }

    trait :venue_owner do
      user_type { "venue" }
    end

    trait :band_leader do
      user_type { "band_leader" }
    end

    trait :with_musician do
      after(:create) do |user|
        create(:musician, user: user)
      end
    end
  end
end
