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

# Add past gig on November 25th, 2025
nov25_gig = band.band_gigs.find_by(date: Date.new(2025, 11, 25))
unless nov25_gig
  BandGig.create!(
    band: band,
    name: 'Shimokitazawa SHELTER Live',
    venue_name: 'SHELTER',
    location: 'Shimokitazawa, Tokyo',
    date: Date.new(2025, 11, 25)
  )
  puts "Created past gig: Shimokitazawa SHELTER Live (Nov 25, 2025)"
end

# Remove old Shimokitazawa SHELTER gig if exists with wrong date
old_shelter_gig = band.band_gigs.find_by(name: 'Shimokitazawa SHELTER')
if old_shelter_gig && old_shelter_gig.date != Date.new(2025, 11, 25)
  old_shelter_gig.destroy
  puts "Removed old SHELTER gig with incorrect date"
end

puts "Updated Neon Pulse stats:"
puts "  Instagram: #{band.instagram_followers}"
puts "  TikTok: #{band.tiktok_followers}"
puts "  YouTube: #{band.youtube_subscribers}"
puts "  Twitter: #{band.twitter_followers}"
puts ""
puts "Band Gigs:"
band.band_gigs.order(:date).each { |g| puts "  - #{g.name} (#{g.date})" }
