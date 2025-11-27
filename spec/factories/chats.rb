FactoryBot.define do
  factory :chat do
    sequence(:name) { |n| "Chat #{n}" }
    band { nil }

    trait :band_chat do
      association :band
      name { "#{band.name} Chat" }
    end

    trait :direct_message do
      band { nil }
      name { "Direct Message" }
    end

    trait :with_participants do
      transient do
        participants { [] }
      end

      after(:create) do |chat, evaluator|
        evaluator.participants.each do |user|
          create(:participation, chat: chat, user: user)
        end
      end
    end
  end
end
