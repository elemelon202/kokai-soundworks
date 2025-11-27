FactoryBot.define do
  factory :musician do
    sequence(:name) { |n| "Musician #{n}" }
    instrument { "Guitar" }
    styles { "Rock, Jazz" }
    location { "New York" }
    bio { "A talented musician" }
    age { 25 }
    user

    trait :bassist do
      instrument { "Bass" }
    end

    trait :drummer do
      instrument { "Drums" }
    end

    trait :vocalist do
      instrument { "Vocals" }
    end
  end
end
