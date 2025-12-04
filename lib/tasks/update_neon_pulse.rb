# Run with: heroku run rails runner lib/tasks/update_neon_pulse.rb

band = Band.find_by(name: 'Neon Pulse')

unless band
  puts "ERROR: Neon Pulse band not found"
  exit 1
end

# Update to realistic local band numbers
band.update!(
  instagram_followers: 847,
  tiktok_followers: 312,
  youtube_subscribers: 89,
  twitter_followers: 156
)

# Add a past gig from a couple months ago (if not already exists)
past_gig = band.band_gigs.find_by(name: 'Shimokitazawa SHELTER')
unless past_gig
  BandGig.create!(
    band: band,
    name: 'Shimokitazawa SHELTER',
    venue_name: 'SHELTER',
    location: 'Shimokitazawa, Tokyo',
    date: Date.today - 2.months
  )
end

puts "Updated Neon Pulse stats:"
puts "  Instagram: #{band.instagram_followers}"
puts "  TikTok: #{band.tiktok_followers}"
puts "  YouTube: #{band.youtube_subscribers}"
puts "  Twitter: #{band.twitter_followers}"
puts ""
puts "Band Gigs:"
band.band_gigs.order(:date).each { |g| puts "  - #{g.name} (#{g.date})" }
