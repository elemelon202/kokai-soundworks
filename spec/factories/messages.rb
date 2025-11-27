FactoryBot.define do
  factory :message do
    content { "Hello, this is a test message" }
    chat
    user

    trait :with_attachment do
      after(:create) do |message|
        create(:attachment, message: message)
      end
    end
  end
end
