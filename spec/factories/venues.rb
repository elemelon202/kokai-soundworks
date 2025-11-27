FactoryBot.define do
  factory :venue do
    sequence(:name) { |n| "Venue #{n}" }
    address { "123 Main Street" }
    city { "Los Angeles" }
    capacity { 500 }
    description { "A great venue for live music" }
    user
  end
end
