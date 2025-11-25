puts "🧹 Cleaning database..."
Attachment.destroy_all
Message.destroy_all
Participation.destroy_all
Chat.destroy_all
KanbanTask.destroy_all
Booking.destroy_all
Gig.destroy_all
Involvement.destroy_all
Band.destroy_all
Musician.destroy_all
Venue.destroy_all
User.destroy_all

puts "✨ Creating users..."

# Venue Owners
venue_owner1 = User.create!(email: "bluenote@venue.com", password: "password123", username: "bluenote_tokyo", user_type: "venue")
venue_owner2 = User.create!(email: "livehouse@venue.com", password: "password123", username: "shibuya_live", user_type: "venue")

# Musicians
musician_user1 = User.create!(email: "yuki.drums@musician.com", password: "password123", username: "yuki_beats", user_type: "musician")
musician_user2 = User.create!(email: "kenji.bass@musician.com", password: "password123", username: "kenji_groove", user_type: "musician")
musician_user3 = User.create!(email: "sakura.vocals@musician.com", password: "password123", username: "sakura_voice", user_type: "musician")
musician_user4 = User.create!(email: "takeshi.guitar@musician.com", password: "password123", username: "takeshi_shred", user_type: "musician")

# Band Leaders
band_leader1 = User.create!(email: "neon@band.com", password: "password123", username: "neon_pulse_band", user_type: "band")
band_leader2 = User.create!(email: "midnight@band.com", password: "password123", username: "midnight_jazz", user_type: "band")

puts "✅ Created #{User.count} users"

puts "🏢 Creating venues..."

venue1 = Venue.create!(user: venue_owner1, name: "Blue Note Tokyo", address: "6-3-16 Minami-Aoyama, Minato-ku", city: "Tokyo", capacity: 300, description: "Premier jazz club in the heart of Tokyo.")
venue2 = Venue.create!(user: venue_owner2, name: "Shibuya Live House", address: "2-10-7 Dogenzaka, Shibuya-ku", city: "Tokyo", capacity: 500, description: "Iconic rock venue in Shibuya.")
venue3 = Venue.create!(user: venue_owner1, name: "Roppongi Underground", address: "4-5-2 Roppongi, Minato-ku", city: "Tokyo", capacity: 200, description: "Underground venue for experimental performances.")

puts "✅ Created #{Venue.count} venues"

puts "🎸 Creating musicians..."

musician1 = Musician.create!(user: musician_user1, name: "Yuki Tanaka", instrument: "Drums", age: 28, styles: "Jazz, Funk, R&B", location: "Shibuya, Tokyo", bio: "Yuki is the rhythmic backbone of any ensemble...")
musician2 = Musician.create!(user: musician_user2, name: "Kenji Watanabe", instrument: "Bass", age: 32, styles: "Jazz, Rock, Blues", location: "Shinjuku, Tokyo", bio: "Kenji is the ultimate musical chameleon...")
musician3 = Musician.create!(user: musician_user3, name: "Sakura Kimura", instrument: "Vocals", age: 25, styles: "Jazz, Soul, Pop", location: "Harajuku, Tokyo", bio: "Sakura is a captivating vocalist...")
musician4 = Musician.create!(user: musician_user4, name: "Takeshi Ito", instrument: "Guitar", age: 30, styles: "Rock, Metal, Blues", location: "Ikebukuro, Tokyo", bio: "Takeshi's guitar work is defined by blistering solos...")

puts "✅ Created #{Musician.count} musicians"

puts "🎵 Creating bands..."

# Bands automatically create chat and add creator as musician and chat participant
band1 = Band.create!(user: band_leader1, name: "Neon Pulse", description: "Electronic rock fusion band.", location: "Shibuya, Tokyo")
band2 = Band.create!(user: band_leader2, name: "Midnight Jazz Collective", description: "Contemporary jazz ensemble.", location: "Shinjuku, Tokyo")
band3 = Band.create!(user: band_leader1, name: "Tokyo Thunder", description: "High-energy rock band.", location: "Roppongi, Tokyo")

puts "✅ Created #{Band.count} bands"

puts "🤝 Creating involvements (band members)..."

# Add musicians to bands
Involvement.create!(band: band1, musician: musician4)
Involvement.create!(band: band1, musician: musician1)

Involvement.create!(band: band2, musician: musician2)
Involvement.create!(band: band2, musician: musician3)
Involvement.create!(band: band2, musician: musician1)

Involvement.create!(band: band3, musician: musician4)

puts "✅ Created #{Involvement.count} involvements"

puts "🎤 Creating gigs..."

gig1 = Gig.create!(venue: venue1, name: "Jazz Night Sessions", date: 3.days.from_now, start_time: 3.days.from_now, end_time: 3.days.from_now, status: "scheduled")
gig2 = Gig.create!(venue: venue2, name: "Rock Festival 2025", date: 1.week.from_now, start_time: 1.week.from_now, end_time: 1.week.from_now, status: "scheduled")
gig3 = Gig.create!(venue: venue3, name: "Experimental Sounds", date: 2.weeks.from_now, start_time: 2.weeks.from_now, end_time: 2.weeks.from_now, status: "scheduled")
gig4 = Gig.create!(venue: venue1, name: "Summer Jam Session", date: 2.days.ago, start_time: 2.days.ago, end_time: 2.days.ago, status: "completed")
gig5 = Gig.create!(venue: venue2, name: "Indie Night", date: 3.weeks.from_now, start_time: 3.weeks.from_now, end_time: 3.weeks.from_now, status: "scheduled")

puts "✅ Created #{Gig.count} gigs"

puts "📋 Creating bookings..."

Booking.create!(band: band2, gig: gig1, message: "We'd love to perform at your jazz night!", status: "approved")
Booking.create!(band: band1, gig: gig2, message: "Neon Pulse is interested in the rock festival slot.", status: "pending")
Booking.create!(band: band3, gig: gig2, message: "Tokyo Thunder ready to rock!", status: "approved")
Booking.create!(band: band1, gig: gig3, message: "Perfect venue for our experimental set.", status: "rejected")
Booking.create!(band: band2, gig: gig5, message: "Would love to headline the indie night.", status: "pending")

puts "✅ Created #{Booking.count} bookings"

puts "💬 Creating messages..."

# Access band chats created automatically
chat1 = band1.chat
chat2 = band2.chat

# Neon Pulse messages
msg1 = Message.create!(chat: chat1, user: band_leader1, content: "Hey everyone! Rehearsal is confirmed for Thursday at 7pm.")
msg2 = Message.create!(chat: chat1, user: musician4.user, content: "Got it! I'll bring the new pedal.")
msg3 = Message.create!(chat: chat1, user: musician1.user, content: "Can we work on the tempo for 'Electric Dreams'?")

# Midnight Jazz messages
msg4 = Message.create!(chat: chat2, user: band_leader2, content: "Great news! Jazz Night Sessions approved!")
msg5 = Message.create!(chat: chat2, user: musician3.user, content: "What songs are we doing?")
msg6 = Message.create!(chat: chat2, user: musician2.user, content: "I suggest we open with 'Midnight in Tokyo'.")

puts "✅ Created #{Message.count} messages"

puts "🎉 Seed complete!"
