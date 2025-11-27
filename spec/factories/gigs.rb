FactoryBot.define do
  factory :gig do
    sequence(:name) { |n| "Gig #{n}" }
    date { Date.today + 7.days }
    start_time { Date.today + 7.days }
    end_time { Date.today + 7.days }
    status { "scheduled" }
    venue
  end
end
