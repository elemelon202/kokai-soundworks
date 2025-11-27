FactoryBot.define do
  factory :booking do
    message { "We would love to play at your venue!" }
    status { "pending" }
    band
    gig
  end
end
