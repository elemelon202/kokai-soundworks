# Clear existing data
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

# Create Venue Owners
venue_owner1 = User.create!(
  email: "bluenote@venue.com",
  password: "password123",
  username: "bluenote_tokyo",
  user_type: "venue"
)

venue_owner2 = User.create!(
  email: "livehouse@venue.com",
  password: "password123",
  username: "shibuya_live",
  user_type: "venue"
)

# Create Musicians
musician_user1 = User.create!(
  email: "yuki.drums@musician.com",
  password: "password123",
  username: "yuki_beats",
  user_type: "musician"
)

musician_user2 = User.create!(
  email: "kenji.bass@musician.com",
  password: "password123",
  username: "kenji_groove",
  user_type: "musician"
)

musician_user3 = User.create!(
  email: "sakura.vocals@musician.com",
  password: "password123",
  username: "sakura_voice",
  user_type: "musician"
)

musician_user4 = User.create!(
  email: "takeshi.guitar@musician.com",
  password: "password123",
  username: "takeshi_shred",
  user_type: "musician"
)

# Create Band Leaders
band_leader1 = User.create!(
  email: "neon@band.com",
  password: "password123",
  username: "neon_pulse_band",
  user_type: "band"
)

band_leader2 = User.create!(
  email: "midnight@band.com",
  password: "password123",
  username: "midnight_jazz",
  user_type: "band"
)

puts "✅ Created #{User.count} users"

puts "🏢 Creating venues..."

venue1 = Venue.create!(
  user: venue_owner1,
  name: "Blue Note Tokyo",
  address: "6-3-16 Minami-Aoyama, Minato-ku",
  city: "Tokyo",
  capacity: 300,
  description: "Premier jazz club in the heart of Tokyo. Intimate atmosphere with world-class acoustics."
)

venue2 = Venue.create!(
  user: venue_owner2,
  name: "Shibuya Live House",
  address: "2-10-7 Dogenzaka, Shibuya-ku",
  city: "Tokyo",
  capacity: 500,
  description: "Iconic rock venue in Shibuya. Known for hosting emerging and established bands."
)

venue3 = Venue.create!(
  user: venue_owner1,
  name: "Roppongi Underground",
  address: "4-5-2 Roppongi, Minato-ku",
  city: "Tokyo",
  capacity: 200,
  description: "Underground venue for experimental and indie performances."
)

puts "✅ Created #{Venue.count} venues"

puts "🎸 Creating musicians..."

musician1 = Musician.create!(
  user: musician_user1,
  name: "Yuki Tanaka",
  instrument: "Drums",
  age: 28,
  styles: "Jazz, Funk, R&B",
  location: "Shibuya, Tokyo"
)

musician2 = Musician.create!(
  user: musician_user2,
  name: "Kenji Watanabe",
  instrument: "Bass",
  age: 32,
  styles: "Jazz, Rock, Blues",
  location: "Shinjuku, Tokyo"
)

musician3 = Musician.create!(
  user: musician_user3,
  name: "Sakura Kimura",
  instrument: "Vocals",
  age: 25,
  styles: "Jazz, Soul, Pop",
  location: "Harajuku, Tokyo"
)

musician4 = Musician.create!(
  user: musician_user4,
  name: "Takeshi Ito",
  instrument: "Guitar",
  age: 30,
  styles: "Rock, Metal, Blues",
  location: "Ikebukuro, Tokyo"
)

puts "✅ Created #{Musician.count} musicians"

puts "🎵 Creating bands..."

band1 = Band.create!(
  user: band_leader1,
  name: "Neon Pulse",
  description: "Electronic rock fusion band pushing boundaries with synth-driven soundscapes."
)

band2 = Band.create!(
  user: band_leader2,
  name: "Midnight Jazz Collective",
  description: "Contemporary jazz ensemble blending traditional and modern influences."
)

band3 = Band.create!(
  user: band_leader1,
  name: "Tokyo Thunder",
  description: "High-energy rock band with a passion for live performances."
)

puts "✅ Created #{Band.count} bands"

puts "🤝 Creating involvements (band members)..."

# Neon Pulse members
Involvement.create!(band: band1, musician: musician4)
Involvement.create!(band: band1, musician: musician1)

# Midnight Jazz Collective members
Involvement.create!(band: band2, musician: musician2)
Involvement.create!(band: band2, musician: musician3)
Involvement.create!(band: band2, musician: musician1)

# Tokyo Thunder members
Involvement.create!(band: band3, musician: musician4)

puts "✅ Created #{Involvement.count} involvements"

puts "🎤 Creating gigs..."

# Note: start_time and end_time are date fields in schema, not time fields
gig1 = Gig.create!(
  venue: venue1,
  name: "Jazz Night Sessions",
  date: 3.days.from_now,
  start_time: 3.days.from_now,
  end_time: 3.days.from_now,
  status: "scheduled"
)

gig2 = Gig.create!(
  venue: venue2,
  name: "Rock Festival 2025",
  date: 1.week.from_now,
  start_time: 1.week.from_now,
  end_time: 1.week.from_now,
  status: "scheduled"
)

gig3 = Gig.create!(
  venue: venue3,
  name: "Experimental Sounds",
  date: 2.weeks.from_now,
  start_time: 2.weeks.from_now,
  end_time: 2.weeks.from_now,
  status: "scheduled"
)

gig4 = Gig.create!(
  venue: venue1,
  name: "Summer Jam Session",
  date: 2.days.ago,
  start_time: 2.days.ago,
  end_time: 2.days.ago,
  status: "completed"
)

gig5 = Gig.create!(
  venue: venue2,
  name: "Indie Night",
  date: 3.weeks.from_now,
  start_time: 3.weeks.from_now,
  end_time: 3.weeks.from_now,
  status: "scheduled"
)

puts "✅ Created #{Gig.count} gigs"

puts "📋 Creating bookings..."

booking1 = Booking.create!(
  band: band2,
  gig: gig1,
  message: "We'd love to perform at your jazz night! We have a new setlist ready.",
  status: "approved"
)

booking2 = Booking.create!(
  band: band1,
  gig: gig2,
  message: "Neon Pulse is interested in the rock festival slot. We can bring a crowd!",
  status: "pending"
)

booking3 = Booking.create!(
  band: band3,
  gig: gig2,
  message: "Tokyo Thunder ready to rock! Let's make this festival unforgettable.",
  status: "approved"
)

booking4 = Booking.create!(
  band: band1,
  gig: gig3,
  message: "Perfect venue for our experimental set. Count us in!",
  status: "rejected"
)

booking5 = Booking.create!(
  band: band2,
  gig: gig5,
  message: "Would love to headline the indie night. Available for soundcheck at 6pm.",
  status: "pending"
)

puts "✅ Created #{Booking.count} bookings"

puts "📝 Creating kanban tasks..."

KanbanTask.create!(
  name: "Record new single",
  status: "in_progress",
  created_by_id: band_leader1.id,
  task_type: "recording",
  deadline: 5.days.from_now,
  description: "Finish recording the vocals and guitar tracks for our new single 'Electric Dreams'",
  position: 0
)

KanbanTask.create!(
  name: "Book studio for mixing",
  status: "to_do",
  created_by_id: band_leader2.id,
  task_type: "booking",
  deadline: 1.week.from_now,
  description: "Need to find a good mixing engineer and book 2 days of studio time",
  position: 1
)

KanbanTask.create!(
  name: "Design album artwork",
  status: "to_do",
  created_by_id: band_leader1.id,
  task_type: "promotion",
  deadline: 2.weeks.from_now,
  description: "Contact designers for EP cover art. Budget: ¥50,000",
  position: 2
)

KanbanTask.create!(
  name: "Rehearse new setlist",
  status: "to_do",
  created_by_id: band_leader2.id,
  task_type: "rehearsal",
  deadline: 3.days.from_now,
  description: "Full band rehearsal for Jazz Night Sessions. Focus on new arrangements.",
  position: 3
)

KanbanTask.create!(
  name: "Fix amp speaker",
  status: "in_progress",
  created_by_id: musician_user4.id,
  task_type: "equipment",
  deadline: 2.days.from_now,
  description: "Marshall amp has buzzing issue. Take to repair shop in Ochanomizu.",
  position: 4
)

KanbanTask.create!(
  name: "Compose bridge section",
  status: "review",
  created_by_id: band_leader1.id,
  task_type: "composition",
  deadline: Date.today,
  description: "New song needs a stronger bridge. Demo is ready for band review.",
  position: 5
)

KanbanTask.create!(
  name: "Update social media",
  status: "done",
  created_by_id: band_leader2.id,
  task_type: "promotion",
  deadline: 1.day.ago,
  description: "Posted gig announcement and rehearsal photos on Instagram and Twitter",
  position: 6
)

puts "✅ Created #{KanbanTask.count} kanban tasks"

puts "💬 Creating chats..."

chat1 = Chat.create!(name: "Neon Pulse Band Chat")
chat2 = Chat.create!(name: "Midnight Jazz Collective")
chat3 = Chat.create!(name: "Venue Booking Discussion")
chat4 = Chat.create!(name: "Equipment Trade")

puts "✅ Created #{Chat.count} chats"

puts "👥 Creating participations..."

# Neon Pulse chat participants
Participation.create!(chat: chat1, user: band_leader1)
Participation.create!(chat: chat1, user: musician_user4)
Participation.create!(chat: chat1, user: musician_user1)

# Midnight Jazz chat participants
Participation.create!(chat: chat2, user: band_leader2)
Participation.create!(chat: chat2, user: musician_user2)
Participation.create!(chat: chat2, user: musician_user3)
Participation.create!(chat: chat2, user: musician_user1)

# Venue booking chat
Participation.create!(chat: chat3, user: venue_owner1)
Participation.create!(chat: chat3, user: band_leader2)

# Equipment trade chat
Participation.create!(chat: chat4, user: musician_user4)
Participation.create!(chat: chat4, user: musician_user2)

puts "✅ Created #{Participation.count} participations"

puts "💌 Creating messages..."

# Neon Pulse band chat
msg1 = Message.create!(
  chat: chat1,
  user: band_leader1,
  content: "Hey everyone! Rehearsal is confirmed for Thursday at 7pm. Don't be late!"
)

msg2 = Message.create!(
  chat: chat1,
  user: musician_user4,
  content: "Got it! I'll bring the new pedal I just got. Sounds amazing."
)

msg3 = Message.create!(
  chat: chat1,
  user: musician_user1,
  content: "Can we work on the tempo for 'Electric Dreams'? I think we should speed it up a bit."
)

# Midnight Jazz chat
msg4 = Message.create!(
  chat: chat2,
  user: band_leader2,
  content: "Great news! We got approved for the Jazz Night Sessions at Blue Note!"
)

msg5 = Message.create!(
  chat: chat2,
  user: musician_user3,
  content: "That's awesome! What songs are we doing?"
)

msg6 = Message.create!(
  chat: chat2,
  user: musician_user2,
  content: "I suggest we open with 'Midnight in Tokyo' and close with 'Blue Horizon'"
)

msg7 = Message.create!(
  chat: chat2,
  user: musician_user1,
  content: "Perfect setlist! Should we add the new arrangement of 'Autumn Leaves'?"
)

# Venue booking chat
msg8 = Message.create!(
  chat: chat3,
  user: band_leader2,
  content: "Hi! We're interested in booking a slot for our band Midnight Jazz Collective."
)

msg9 = Message.create!(
  chat: chat3,
  user: venue_owner1,
  content: "Thanks for reaching out! We have availability on the 28th. What time works for you?"
)

msg10 = Message.create!(
  chat: chat3,
  user: band_leader2,
  content: "7pm would be perfect. We'll need about 3 hours including soundcheck."
)

# Equipment trade chat
msg11 = Message.create!(
  chat: chat4,
  user: musician_user4,
  content: "Anyone interested in a Fender Stratocaster? Thinking of switching to a Les Paul."
)

msg12 = Message.create!(
  chat: chat4,
  user: musician_user2,
  content: "What year? I might be interested depending on the condition."
)

puts "✅ Created #{Message.count} messages"

puts "📎 Creating attachments..."

Attachment.create!(
  message: msg1,
  file_url: "https://example.com/files/rehearsal-schedule.pdf",
  file_name: "rehearsal_schedule.pdf",
  file_type: "application/pdf"
)

Attachment.create!(
  message: msg2,
  file_url: "https://example.com/files/pedal-demo.mp3",
  file_name: "new_pedal_sound.mp3",
  file_type: "audio/mpeg"
)

Attachment.create!(
  message: msg7,
  file_url: "https://example.com/files/setlist.jpg",
  file_name: "jazz_night_setlist.jpg",
  file_type: "image/jpeg"
)

puts "✅ Created #{Attachment.count} attachments"

puts ""
puts "🎉 Seed data created successfully!"
puts ""
puts "📊 Summary:"
puts "  👤 Users: #{User.count}"
puts "  🏢 Venues: #{Venue.count}"
puts "  🎸 Musicians: #{Musician.count}"
puts "  🎵 Bands: #{Band.count}"
puts "  🤝 Involvements: #{Involvement.count}"
puts "  🎤 Gigs: #{Gig.count}"
puts "  📋 Bookings: #{Booking.count}"
puts "  📝 Kanban Tasks: #{KanbanTask.count}"
puts "  💬 Chats: #{Chat.count}"
puts "  👥 Participations: #{Participation.count}"
puts "  💌 Messages: #{Message.count}"
puts "  📎 Attachments: #{Attachment.count}"
puts ""
puts "🔐 Login credentials (all passwords: 'password123'):"
puts "  Venue Owner: bluenote@venue.com"
puts "  Musician: yuki.drums@musician.com"
puts "  Band Leader: neon@band.com"
