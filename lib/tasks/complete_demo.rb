# Run this with: heroku run rails runner lib/tasks/complete_demo.rb

fg = FundedGig.joins(:gig).where("gigs.name LIKE ?", "%Neon%").first
fg ||= FundedGig.accepting_pledges.order(created_at: :desc).first

unless fg
  puts "ERROR: No funded gig found"
  exit 1
end

puts "Before pledge:"
puts "  Current: ¥#{fg.current_pledged_cents}"
puts "  Target: ¥#{fg.funding_target_cents}"
puts "  Percentage: #{fg.funding_percentage}%"

# Find a user who hasn't pledged yet
user = User.where(user_type: 'fan').where.not(id: fg.pledges.pluck(:user_id)).first
user ||= User.where(user_type: 'musician').where.not(id: fg.pledges.pluck(:user_id)).first

unless user
  puts "ERROR: No available user found to pledge"
  exit 1
end

puts "  Using user: #{user.email}"

# Create the pledge
pledge = Pledge.create!(
  funded_gig: fg,
  user: user,
  amount_cents: 3000,
  status: :authorized,
  fan_message: "Making this happen!"
)

fg.reload

puts ""
puts "After pledge of ¥3000:"
puts "  Current: ¥#{fg.current_pledged_cents}"
puts "  Target: ¥#{fg.funding_target_cents}"
puts "  Percentage: #{fg.funding_percentage}%"

if fg.funding_reached?
  puts ""
  puts "🎉 FUNDING GOAL REACHED! 🎉"
end
