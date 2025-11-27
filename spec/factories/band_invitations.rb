FactoryBot.define do
  factory :band_invitation do
    band
    musician
    inviter factory: :user
    status { "Pending" }
    token { SecureRandom.hex(20) }

    trait :accepted do
      status { "Accepted" }
    end

    trait :declined do
      status { "Declined" }
    end
  end
end
