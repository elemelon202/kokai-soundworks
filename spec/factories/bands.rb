FactoryBot.define do
  factory :band do
    sequence(:name) { |n| "Band #{n}" }
    description { "A great band" }
    location { "Los Angeles" }
    user

    trait :with_genres do
      after(:create) do |band|
        band.genre_list.add("Rock", "Jazz")
        band.save
      end
    end

    # Factory that skips the after_create callback for testing purposes
    factory :band_without_callback do
      after(:build) do |band|
        band.class.skip_callback(:create, :after, :setup_band_membership_and_chat)
      end

      after(:create) do |band|
        band.class.set_callback(:create, :after, :setup_band_membership_and_chat)
      end
    end
  end
end
