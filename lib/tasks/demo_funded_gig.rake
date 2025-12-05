# frozen_string_literal: true

namespace :demo do
  desc "Set up a demo funded gig for Neon Pulse band - nearly funded and ready for dramatic finish"
  task setup_funded_gig: :environment do
    puts "Setting up demo funded gig..."

    # Find or identify the key entities
    neon_pulse = Band.find_by(name: "Neon Pulse")
    unless neon_pulse
      puts "ERROR: Neon Pulse band not found. Please ensure seeds have been run."
      exit 1
    end

    blue_note = Venue.find_by(name: "Blue Note Tokyo")
    unless blue_note
      puts "ERROR: Blue Note Tokyo venue not found. Please ensure seeds have been run."
      exit 1
    end

    # Get all users for mock pledges (need ~40 backers)
    # Exclude Neon Pulse owner and Special_K (used as demo login account)
    special_k = Musician.find_by(name: "Special_K")
    excluded_user_ids = [neon_pulse.user_id, special_k&.user_id].compact
    all_users = User.where.not(id: excluded_user_ids).to_a
    if all_users.count < 40
      puts "WARNING: Only #{all_users.count} users available for pledges (wanted 40)"
    end

    # Find the reference gig (funded_gig 14) to copy the poster from
    reference_funded_gig = FundedGig.find_by(id: 14)
    reference_gig = reference_funded_gig&.gig

    # Create the demo gig
    demo_gig = Gig.find_or_create_by!(
      venue: blue_note,
      name: "Neon Nights: Community Powered"
    ) do |gig|
      gig.date = Date.current + 14.days
      gig.start_time = Time.zone.parse("19:00")
      gig.end_time = Time.zone.parse("22:00")
    end
    puts "Created/found gig: #{demo_gig.name}"

    # Copy poster from reference gig if available
    if reference_gig&.poster&.attached? && !demo_gig.poster.attached?
      demo_gig.poster.attach(reference_gig.poster.blob)
      puts "Copied poster from funded_gig 14"
    end

    # Create the funded gig with a target of 50,000 yen
    # 40 backers × ~1,250 yen avg = ~50,000 yen
    # We'll have 39 backers totaling ~48,750 yen, leaving ~1,250 for the dramatic finish
    funding_target = 50000

    # Delete existing funded gig if present to reset
    if demo_gig.funded_gig.present?
      demo_gig.funded_gig.pledges.destroy_all
      demo_gig.funded_gig.destroy
    end

    funded_gig = FundedGig.create!(
      gig: demo_gig,
      funding_target_cents: funding_target,
      current_pledged_cents: 0,
      funding_status: :accepting_pledges,
      deadline_days_before: 7,
      max_bands: 3,
      allow_partial_funding: false,
      minimum_funding_percent: 80,
      venue_message: "Help us bring Neon Pulse to Blue Note Tokyo! This is a community-powered show - if we reach our funding goal, all pledgers get free tickets. Let's make this happen together!",
      applications_open_at: 3.days.ago,
      pledging_opens_at: 1.day.ago
    )
    puts "Created funded gig with target: ¥#{funding_target}"

    # Create booking for Neon Pulse
    Booking.find_or_create_by!(gig: demo_gig, band: neon_pulse)
    puts "Booked Neon Pulse for the gig"

    # Create an approved application for Neon Pulse
    app = GigApplication.find_or_initialize_by(gig: demo_gig, band: neon_pulse)
    app.status = :approved
    app.mainstage_score_at_application = 850
    app.follower_count_at_application = neon_pulse.follows.count
    app.past_gig_count = neon_pulse.gigs.where('date < ?', Date.current).count
    app.save!
    puts "Created approved application for Neon Pulse"

    # Create 39 mock pledges with realistic amounts (1000-1500 yen each)
    # Total should be ~48,750 yen, leaving ~1,250 for the dramatic final pledge
    fan_messages = [
      "Go Neon Pulse!", "Can't wait for this show!", "Supporting live music!",
      "Let's make this happen!", "Amazing band!", "Love your music!",
      "See you there!", "Best band in Tokyo!", "Take my money!",
      "This is going to be epic!", "Finally a free show!", "Count me in!",
      "Supporting local music!", "You guys rock!", "Let's go!",
      "Been waiting for this!", "Excited!", "This band deserves it!",
      "Great cause!", "Music brings us together!", "Shibuya represent!",
      "Underground heroes!", "Real music!", "Let's pack the venue!",
      "Community power!", "Indie forever!", "Live music matters!",
      "Can't miss this!", "Bringing friends!", "Let's do this!",
      "Supporting the scene!", "Tokyo underground!", "Making memories!",
      "Best investment!", "Music is life!", "Let's goooo!",
      "Neon Pulse forever!", "Dream show!", "History in the making!"
    ]

    # Generate pledge amounts using realistic rounded numbers (1000, 1500, or 2000 yen)
    # Target: ~48,000 yen, leaving ~2,000 for the dramatic final pledge
    # With avg ~1,350 yen per pledge, we need about 35-36 pledges

    # Use only realistic rounded amounts that people would actually pledge
    # Fixed distribution to ensure we stay under 50,000: 20x ¥1000, 10x ¥1500, 6x ¥2000 = 47,000
    pledge_amounts = []
    20.times { pledge_amounts << 1000 }  # 20 × 1000 = 20,000
    10.times { pledge_amounts << 1500 }  # 10 × 1500 = 15,000
    6.times { pledge_amounts << 2000 }   # 6 × 2000 = 12,000
    # Total: 47,000 yen with 36 backers, leaving 3,000 for dramatic finish

    # Shuffle to make it look natural
    pledge_amounts.shuffle!
    num_pledges = pledge_amounts.count

    pledges_created = 0
    users_for_pledges = all_users.shuffle.take(num_pledges)

    users_for_pledges.each_with_index do |user, index|
      # Skip if pledge already exists
      next if Pledge.exists?(funded_gig: funded_gig, user: user)

      Pledge.create!(
        funded_gig: funded_gig,
        user: user,
        amount_cents: pledge_amounts[index],
        status: :authorized,
        fan_message: fan_messages[index % fan_messages.length],
        anonymous: rand < 0.15  # 15% anonymous
      )
      pledges_created += 1
    end

    funded_gig.reload
    puts "Created #{pledges_created} mock pledges"
    puts ""
    puts "=" * 60
    puts "DEMO FUNDED GIG SETUP COMPLETE!"
    puts "=" * 60
    puts ""
    puts "Funded Gig: #{funded_gig.name}"
    puts "Backers: #{funded_gig.pledges.count} supporters"
    puts "Current Funding: ¥#{funded_gig.current_pledged_cents.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} / ¥#{funded_gig.funding_target_cents.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "Percentage: #{funded_gig.funding_percentage}%"
    puts "Remaining to fund: ¥#{funded_gig.amount_remaining.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts ""
    puts "URL: /funded-gigs/#{funded_gig.id}"
    puts ""
    puts "To complete funding during the presentation, run:"
    puts "  heroku run rails runner lib/tasks/complete_demo.rb"
    puts ""
  end

  desc "Add the final pledge to complete funding (run during presentation)"
  task :complete_funding, [:user_email, :amount] => :environment do |t, args|
    user_email = args[:user_email] || "akira.fan@email.com"
    amount = (args[:amount] || 3000).to_i

    user = User.find_by(email: user_email)
    unless user
      puts "ERROR: User with email #{user_email} not found"
      exit 1
    end

    # Find the demo funded gig (most recent accepting pledges)
    funded_gig = FundedGig.accepting_pledges.joins(:gig).where("gigs.name LIKE ?", "%Neon%").first
    funded_gig ||= FundedGig.accepting_pledges.order(created_at: :desc).first

    unless funded_gig
      puts "ERROR: No funded gig accepting pledges found"
      exit 1
    end

    puts "Before pledge:"
    puts "  Current: ¥#{funded_gig.current_pledged_cents}"
    puts "  Target: ¥#{funded_gig.funding_target_cents}"
    puts "  Percentage: #{funded_gig.funding_percentage}%"

    # Create the final pledge
    pledge = Pledge.create!(
      funded_gig: funded_gig,
      user: user,
      amount_cents: amount,
      status: :authorized,
      fan_message: "Let's make this happen!"
    )

    funded_gig.reload

    puts ""
    puts "After pledge of ¥#{amount}:"
    puts "  Current: ¥#{funded_gig.current_pledged_cents}"
    puts "  Target: ¥#{funded_gig.funding_target_cents}"
    puts "  Percentage: #{funded_gig.funding_percentage}%"

    if funded_gig.funding_reached?
      puts ""
      puts "🎉 FUNDING GOAL REACHED! 🎉"
    end
  end

  desc "Reset the demo funded gig (remove final pledge so it can be done again)"
  task reset_funding: :environment do
    funded_gig = FundedGig.joins(:gig).where("gigs.name LIKE ?", "%Neon%").first

    unless funded_gig
      puts "No Neon Pulse funded gig found"
      exit 1
    end

    # Keep only the first 39 pledges (the setup ones)
    pledges_to_delete = funded_gig.pledges.order(:created_at).offset(39)
    count = pledges_to_delete.count
    pledges_to_delete.destroy_all

    funded_gig.reload

    puts "Deleted #{count} extra pledges"
    puts "Backers: #{funded_gig.pledges.count}"
    puts "Current funding: ¥#{funded_gig.current_pledged_cents} / ¥#{funded_gig.funding_target_cents} (#{funded_gig.funding_percentage}%)"
  end
end
