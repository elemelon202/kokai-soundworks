puts "Cleaning database..."
Notification.destroy_all
BandInvitation.destroy_all
Attachment.destroy_all
MessageRead.destroy_all
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

puts "Creating users..."

# ===========================================
# VENUE OWNERS
# ===========================================
venue_owners = []
venue_owners << User.create!(email: "bluenote@venue.com", password: "password123", username: "bluenote_tokyo", user_type: "venue")
venue_owners << User.create!(email: "livehouse@venue.com", password: "password123", username: "shibuya_live", user_type: "venue")
venue_owners << User.create!(email: "underground@venue.com", password: "password123", username: "roppongi_underground", user_type: "venue")
venue_owners << User.create!(email: "osaka.hall@venue.com", password: "password123", username: "osaka_hall", user_type: "venue")
venue_owners << User.create!(email: "kyoto.jazz@venue.com", password: "password123", username: "kyoto_jazz_spot", user_type: "venue")

# ===========================================
# MUSICIANS (standalone, not band leaders)
# ===========================================
#
band_leaders = []
band_leaders << User.create!(email: "neon@band.com", password: "password123", username: "neon_pulse_band", user_type: "band")
band_leaders << User.create!(email: "midnight@band.com", password: "password123", username: "midnight_jazz", user_type: "band")
band_leaders << User.create!(email: "thunder@band.com", password: "password123", username: "tokyo_thunder", user_type: "band")
band_leaders << User.create!(email: "sakura.ensemble@band.com", password: "password123", username: "sakura_ensemble", user_type: "band")
band_leaders << User.create!(email: "electric.dreams@band.com", password: "password123", username: "electric_dreams", user_type: "band")
band_leaders << User.create!(email: "acoustic.soul@band.com", password: "password123", username: "acoustic_soul", user_type: "band")

musician_users = []
musician_users << User.create!(email: "yuki.drums@musician.com", password: "password123", username: "yuki_beats", user_type: "musician")
musician_users << User.create!(email: "kenji.bass@musician.com", password: "password123", username: "kenji_groove", user_type: "musician")
musician_users << User.create!(email: "sakura.vocals@musician.com", password: "password123", username: "sakura_voice", user_type: "musician")
musician_users << User.create!(email: "takeshi.guitar@musician.com", password: "password123", username: "takeshi_shred", user_type: "musician")
musician_users << User.create!(email: "hiroshi.keys@musician.com", password: "password123", username: "hiroshi_keys", user_type: "musician")
musician_users << User.create!(email: "mika.sax@musician.com", password: "password123", username: "mika_sax", user_type: "musician")
musician_users << User.create!(email: "ryo.trumpet@musician.com", password: "password123", username: "ryo_brass", user_type: "musician")
musician_users << User.create!(email: "aoi.violin@musician.com", password: "password123", username: "aoi_strings", user_type: "musician")
musician_users << User.create!(email: "ken.percussion@musician.com", password: "password123", username: "ken_rhythm", user_type: "musician")
musician_users << User.create!(email: "yumi.vocals@musician.com", password: "password123", username: "yumi_harmony", user_type: "musician")
musician_users << User.create!(email: "daiki.guitar@musician.com", password: "password123", username: "daiki_acoustic", user_type: "musician")
musician_users << User.create!(email: "emi.synth@musician.com", password: "password123", username: "emi_synth", user_type: "musician")

# Additional 50 musicians
musician_users << User.create!(email: "naomi.piano@musician.com", password: "password123", username: "naomi_keys", user_type: "musician")
musician_users << User.create!(email: "taro.drums@musician.com", password: "password123", username: "taro_sticks", user_type: "musician")
musician_users << User.create!(email: "mari.flute@musician.com", password: "password123", username: "mari_wind", user_type: "musician")
musician_users << User.create!(email: "shota.bass@musician.com", password: "password123", username: "shota_lowend", user_type: "musician")
musician_users << User.create!(email: "hana.vocals@musician.com", password: "password123", username: "hana_sing", user_type: "musician")
musician_users << User.create!(email: "koji.guitar@musician.com", password: "password123", username: "koji_riff", user_type: "musician")
musician_users << User.create!(email: "rina.cello@musician.com", password: "password123", username: "rina_strings", user_type: "musician")
musician_users << User.create!(email: "masato.sax@musician.com", password: "password123", username: "masato_horn", user_type: "musician")
musician_users << User.create!(email: "yuna.harp@musician.com", password: "password123", username: "yuna_harp", user_type: "musician")
musician_users << User.create!(email: "shin.drums@musician.com", password: "password123", username: "shin_beats", user_type: "musician")
musician_users << User.create!(email: "akiko.violin@musician.com", password: "password123", username: "akiko_bow", user_type: "musician")
musician_users << User.create!(email: "jun.bass@musician.com", password: "password123", username: "jun_groove", user_type: "musician")
musician_users << User.create!(email: "misaki.vocals@musician.com", password: "password123", username: "misaki_voice", user_type: "musician")
musician_users << User.create!(email: "ryota.guitar@musician.com", password: "password123", username: "ryota_shred", user_type: "musician")
musician_users << User.create!(email: "ayumi.keys@musician.com", password: "password123", username: "ayumi_synth", user_type: "musician")
musician_users << User.create!(email: "kazuki.trumpet@musician.com", password: "password123", username: "kazuki_brass", user_type: "musician")
musician_users << User.create!(email: "saki.clarinet@musician.com", password: "password123", username: "saki_reed", user_type: "musician")
musician_users << User.create!(email: "tomoya.percussion@musician.com", password: "password123", username: "tomoya_rhythm", user_type: "musician")
musician_users << User.create!(email: "natsuki.vocals@musician.com", password: "password123", username: "natsuki_melody", user_type: "musician")
musician_users << User.create!(email: "haruki.guitar@musician.com", password: "password123", username: "haruki_pick", user_type: "musician")
musician_users << User.create!(email: "mei.piano@musician.com", password: "password123", username: "mei_ivories", user_type: "musician")
musician_users << User.create!(email: "kenta.drums@musician.com", password: "password123", username: "kenta_crash", user_type: "musician")
musician_users << User.create!(email: "nanami.flute@musician.com", password: "password123", username: "nanami_air", user_type: "musician")
musician_users << User.create!(email: "yuto.bass@musician.com", password: "password123", username: "yuto_thump", user_type: "musician")
musician_users << User.create!(email: "kokoro.vocals@musician.com", password: "password123", username: "kokoro_soul", user_type: "musician")
musician_users << User.create!(email: "sota.guitar@musician.com", password: "password123", username: "sota_fret", user_type: "musician")
musician_users << User.create!(email: "honoka.viola@musician.com", password: "password123", username: "honoka_alto", user_type: "musician")
musician_users << User.create!(email: "kaito.sax@musician.com", password: "password123", username: "kaito_smooth", user_type: "musician")
musician_users << User.create!(email: "asuka.oboe@musician.com", password: "password123", username: "asuka_double", user_type: "musician")
musician_users << User.create!(email: "ren.drums@musician.com", password: "password123", username: "ren_pocket", user_type: "musician")
musician_users << User.create!(email: "chiaki.violin@musician.com", password: "password123", username: "chiaki_virtuoso", user_type: "musician")
musician_users << User.create!(email: "makoto.bass@musician.com", password: "password123", username: "makoto_slap", user_type: "musician")
musician_users << User.create!(email: "hikari.vocals@musician.com", password: "password123", username: "hikari_light", user_type: "musician")
musician_users << User.create!(email: "yusuke.guitar@musician.com", password: "password123", username: "yusuke_tone", user_type: "musician")
musician_users << User.create!(email: "momoka.keys@musician.com", password: "password123", username: "momoka_chords", user_type: "musician")
musician_users << User.create!(email: "taiga.trombone@musician.com", password: "password123", username: "taiga_slide", user_type: "musician")
musician_users << User.create!(email: "risa.bassoon@musician.com", password: "password123", username: "risa_low", user_type: "musician")
musician_users << User.create!(email: "hayato.percussion@musician.com", password: "password123", username: "hayato_mallet", user_type: "musician")
musician_users << User.create!(email: "manami.vocals@musician.com", password: "password123", username: "manami_range", user_type: "musician")
musician_users << User.create!(email: "shun.guitar@musician.com", password: "password123", username: "shun_blues", user_type: "musician")
musician_users << User.create!(email: "kaori.piano@musician.com", password: "password123", username: "kaori_classical", user_type: "musician")
musician_users << User.create!(email: "naoto.drums@musician.com", password: "password123", username: "naoto_jazz", user_type: "musician")
musician_users << User.create!(email: "yuina.flute@musician.com", password: "password123", username: "yuina_silver", user_type: "musician")
musician_users << User.create!(email: "riku.bass@musician.com", password: "password123", username: "riku_funk", user_type: "musician")
musician_users << User.create!(email: "miyu.vocals@musician.com", password: "password123", username: "miyu_star", user_type: "musician")
musician_users << User.create!(email: "takumi.guitar@musician.com", password: "password123", username: "takumi_lead", user_type: "musician")
musician_users << User.create!(email: "ai.cello@musician.com", password: "password123", username: "ai_deep", user_type: "musician")
musician_users << User.create!(email: "keita.sax@musician.com", password: "password123", username: "keita_alto", user_type: "musician")
musician_users << User.create!(email: "hinata.french_horn@musician.com", password: "password123", username: "hinata_horn", user_type: "musician")
musician_users << User.create!(email: "sora.drums@musician.com", password: "password123", username: "sora_sky", user_type: "musician")

# ===========================================
# BAND LEADERS
# ===========================================

puts "Created #{User.count} users"

# ===========================================
# VENUES
# ===========================================
puts "Creating venues..."

venues = []
# Tokyo venues
venues << Venue.create!(
  user: venue_owners[0],
  name: "Blue Note Tokyo",
  address: "6-3-16 Minami-Aoyama, Minato-ku",
  city: "Tokyo",
  capacity: 300,
  description: "Premier jazz club in the heart of Tokyo. World-renowned for hosting legendary jazz artists and emerging talents alike. Intimate atmosphere with exceptional acoustics and a full dinner menu."
)

venues << Venue.create!(
  user: venue_owners[1],
  name: "Shibuya Live House",
  address: "2-10-7 Dogenzaka, Shibuya-ku",
  city: "Tokyo",
  capacity: 500,
  description: "Iconic rock venue in the heart of Shibuya's entertainment district. Known for launching careers of Japan's biggest rock bands. State-of-the-art sound system and lighting."
)

venues << Venue.create!(
  user: venue_owners[2],
  name: "Roppongi Underground",
  address: "4-5-2 Roppongi, Minato-ku",
  city: "Tokyo",
  capacity: 200,
  description: "Underground venue for experimental and electronic performances. Raw industrial aesthetic with cutting-edge audio-visual capabilities."
)

venues << Venue.create!(
  user: venue_owners[0],
  name: "Shinjuku Loft",
  address: "1-12-9 Kabukicho, Shinjuku-ku",
  city: "Tokyo",
  capacity: 400,
  description: "Historic live house that has been a cornerstone of Tokyo's indie music scene since 1976. Multiple stages and legendary reputation."
)

# Osaka venues
venues << Venue.create!(
  user: venue_owners[3],
  name: "Osaka Billboard Live",
  address: "2-2-22 Umeda, Kita-ku",
  city: "Osaka",
  capacity: 350,
  description: "Upscale concert venue featuring international and domestic acts. Premium dining experience with panoramic city views."
)

venues << Venue.create!(
  user: venue_owners[3],
  name: "Club Quattro Osaka",
  address: "1-8-17 Shinsaibashi-suji, Chuo-ku",
  city: "Osaka",
  capacity: 450,
  description: "Part of the legendary Club Quattro chain. Known for bringing cutting-edge international acts to Osaka's music fans."
)

# Kyoto venues
venues << Venue.create!(
  user: venue_owners[4],
  name: "Kyoto Jazz Spot Yamatoya",
  address: "577 Nakano-cho, Nakagyo-ku",
  city: "Kyoto",
  capacity: 80,
  description: "Intimate jazz bar in a traditional machiya townhouse. Perfect blend of Kyoto's cultural heritage and world-class jazz."
)

venues << Venue.create!(
  user: venue_owners[4],
  name: "Metro Kyoto",
  address: "Keihan Bldg B1F, Marutamachi-dori",
  city: "Kyoto",
  capacity: 250,
  description: "Kyoto's premier club venue for electronic and alternative music. Legendary weekend events and international DJ lineups."
)

puts "Created #{Venue.count} venues"

# ===========================================
# MUSICIANS
# ===========================================
puts "Creating musicians..."

musicians = []
instruments = ["Guitar", "Bass", "Drums", "Vocals", "Keyboard", "Saxophone", "Violin"]
locations = ["Tokyo", "Osaka", "Kyoto", "Yokohama", "Kawasaki", "Kobe", "Sapporo"]
musicians << Musician.create!(
  user: musician_users[0],
  name: "Yuki Tanaka",
  instrument: instruments.sample,
  age: 28,
  styles: "Jazz, Funk, R&B",
  location: locations.sample,
  bio: "Yuki is the rhythmic backbone of any ensemble. With a background in jazz studies at Berklee College of Music, she brings technical precision and creative flair to every performance. Known for her explosive solos and impeccable timing."
)

musicians << Musician.create!(
  user: musician_users[1],
  name: "Kenji Watanabe",
  instrument: instruments.sample,
  age: 32,
  styles: "Jazz, Rock, Blues",
  location: locations.sample,
  bio: "Kenji is the ultimate musical chameleon, seamlessly transitioning between upright bass for jazz gigs and electric bass for rock shows. His groove-heavy playing style has made him one of Tokyo's most sought-after session musicians."
)

musicians << Musician.create!(
  user: musician_users[2],
  name: "Sakura Kimura",
  instrument: instruments.sample,
  age: 25,
  styles: "Jazz, Soul, Pop",
  location: locations.sample,
  bio: "Sakura is a captivating vocalist with a four-octave range. Her soulful interpretations of jazz standards and original compositions have earned her a devoted following in Tokyo's jazz scene."
)

musicians << Musician.create!(
  user: musician_users[3],
  name: "Takeshi Ito",
  instrument: instruments.sample,
  age: 30,
  styles: "Rock, Metal, Blues",
  location: locations.sample,
  bio: "Takeshi's guitar work is defined by blistering solos and heavy riffs. A graduate of MI Japan, he has toured extensively throughout Asia and brings stadium-level energy to every club show."
)

musicians << Musician.create!(
  user: musician_users[4],
  name: "Hiroshi Nakamura",
  instrument: instruments.sample,
  age: 35,
  styles: "Jazz, Classical, Electronic",
  location: locations.sample,
  bio: "Hiroshi bridges the worlds of classical training and modern electronic music. His virtuosic piano technique combined with synth programming creates unique soundscapes that defy categorization."
)

musicians << Musician.create!(
  user: musician_users[5],
  name: "Mika Yoshida",
  instrument: instruments.sample,
  age: 29,
  styles: "Jazz, Funk, Soul",
  location: locations.sample,
  bio: "Mika's saxophone playing channels the spirit of classic soul and modern jazz. Her warm tone and improvisational skills make her a standout in any ensemble."
)

musicians << Musician.create!(
  user: musician_users[6],
  name: "Ryo Fujimoto",
  instrument: instruments.sample,
  age: 27,
  styles: "Jazz, Latin, Fusion",
  location: locations.sample,
  bio: "Ryo brings Latin fire to Tokyo's jazz scene. His trumpet playing is influenced by Afro-Cuban traditions, and he leads his own salsa band on weekends."
)

musicians << Musician.create!(
  user: musician_users[7],
  name: "Aoi Suzuki",
  instrument: instruments.sample,
  age: 24,
  styles: "Classical, Jazz, Folk",
  location: locations.sample,
  bio: "Aoi is a classically trained violinist who discovered jazz in college. She brings orchestral elegance to jazz standards and has collaborated with artists across multiple genres."
)

musicians << Musician.create!(
  user: musician_users[8],
  name: "Ken Yamamoto",
  instrument: instruments.sample,
  age: 33,
  styles: "World Music, Jazz, Electronic",
  location: locations.sample,
  bio: "Ken specializes in world percussion instruments from djembe to tabla. His rhythmic explorations blend traditional techniques with modern electronic production."
)

musicians << Musician.create!(
  user: musician_users[9],
  name: "Yumi Hayashi",
  instrument: instruments.sample,
  age: 26,
  styles: "Pop, R&B, Jazz",
  location: locations.sample,
  bio: "Yumi's silky vocals have graced countless studio sessions. Her background singers work and solo performances showcase incredible range and emotional depth."
)

musicians << Musician.create!(
  user: musician_users[10],
  name: "Daiki Morita",
  instrument: instruments.sample,
  age: 31,
  styles: "Folk, Acoustic, Singer-Songwriter",
  location: locations.sample,
  bio: "Daiki is a masterful fingerstyle guitarist and singer-songwriter. His intimate acoustic performances have built a devoted following in Tokyo's coffee house circuit."
)

musicians << Musician.create!(
  user: musician_users[11],
  name: "Emi Takahashi",
  instrument: instruments.sample,
  age: 28,
  styles: "Electronic, Ambient, Experimental",
  location: locations.sample,
  bio: "Emi creates immersive electronic soundscapes using modular synthesizers and custom software. Her live performances are audio-visual experiences that push boundaries."
)

# Additional 50 musicians
musicians << Musician.create!(
  user: musician_users[12],
  name: "Naomi Sato",
  instrument: instruments.sample,
  age: 29,
  styles: "Classical, Jazz, Contemporary",
  location: locations.sample,
  bio: "Naomi is a classically trained pianist with a passion for jazz improvisation. Her elegant touch and expressive playing have made her a favorite at upscale venues."
)

musicians << Musician.create!(
  user: musician_users[13],
  name: "Taro Ogawa",
  instrument: instruments.sample,
  age: 34,
  styles: "Rock, Punk, Alternative",
  location: locations.sample,
  bio: "Taro brings raw energy and precision to every performance. His powerful drumming style has been the backbone of several influential Tokyo punk bands."
)

musicians << Musician.create!(
  user: musician_users[14],
  name: "Mari Kobayashi",
  instrument: instruments.sample,
  age: 26,
  styles: "Classical, World Music, New Age",
  location: locations.sample,
  bio: "Mari's flute playing transports listeners to ethereal realms. Trained at Tokyo University of the Arts, she blends classical technique with world music influences."
)

musicians << Musician.create!(
  user: musician_users[15],
  name: "Shota Matsuda",
  instrument: instruments.sample,
  age: 30,
  styles: "Funk, R&B, Neo-Soul",
  location: locations.sample,
  bio: "Shota's funky bass lines are infectious and groove-heavy. He's played with numerous R&B artists and brings serious pocket to every session."
)

musicians << Musician.create!(
  user: musician_users[16],
  name: "Hana Ishikawa",
  instrument: instruments.sample,
  age: 23,
  styles: "J-Pop, R&B, Dance",
  location: locations.sample,
  bio: "Hana is a rising star in Tokyo's pop scene. Her powerful voice and charismatic stage presence have garnered a growing fanbase on social media."
)

musicians << Musician.create!(
  user: musician_users[17],
  name: "Koji Taniguchi",
  instrument: instruments.sample,
  age: 36,
  styles: "Blues, Rock, Jazz Fusion",
  location: locations.sample,
  bio: "Koji is a guitar virtuoso known for his soulful blues licks and technical prowess. He runs a popular guitar workshop in Shimokitazawa."
)

musicians << Musician.create!(
  user: musician_users[18],
  name: "Rina Yamada",
  instrument: instruments.sample,
  age: 27,
  styles: "Classical, Chamber Music, Film Scores",
  location: locations.sample,
  bio: "Rina's cello playing is deeply emotional and technically brilliant. She frequently performs with orchestras and records for film soundtracks."
)

musicians << Musician.create!(
  user: musician_users[19],
  name: "Masato Kondo",
  instrument: instruments.sample,
  age: 31,
  styles: "Jazz, Bebop, Hard Bop",
  location: locations.sample,
  bio: "Masato channels the spirit of classic bebop through his saxophone. His improvisations are inventive and deeply rooted in jazz tradition."
)

musicians << Musician.create!(
  user: musician_users[20],
  name: "Yuna Miyamoto",
  instrument: instruments.sample,
  age: 25,
  styles: "Classical, Celtic, Ambient",
  location: locations.sample,
  bio: "Yuna's harp playing creates magical atmospheres. She performs at weddings, corporate events, and intimate concert settings."
)

musicians << Musician.create!(
  user: musician_users[21],
  name: "Shin Okamoto",
  instrument: instruments.sample,
  age: 28,
  styles: "Jazz, Fusion, Progressive",
  location: locations.sample,
  bio: "Shin is a technically gifted drummer who pushes rhythmic boundaries. His complex polyrhythms and dynamic playing are highly sought after."
)

musicians << Musician.create!(
  user: musician_users[22],
  name: "Akiko Endo",
  instrument: instruments.sample,
  age: 32,
  styles: "Classical, Tango, Crossover",
  location: locations.sample,
  bio: "Akiko's violin playing spans classical concertos to passionate tango. She leads her own tango ensemble and performs internationally."
)

musicians << Musician.create!(
  user: musician_users[23],
  name: "Jun Nishimura",
  instrument: instruments.sample,
  age: 29,
  styles: "Progressive Rock, Metal, Jazz Fusion",
  location: locations.sample,
  bio: "Jun is a bass virtuoso known for his technical mastery and musicality. His YouTube tutorials have millions of views worldwide."
)

musicians << Musician.create!(
  user: musician_users[24],
  name: "Misaki Honda",
  instrument: instruments.sample,
  age: 27,
  styles: "Jazz, Bossa Nova, French Chanson",
  location: locations.sample,
  bio: "Misaki's sultry voice and sophisticated phrasing make her a standout jazz vocalist. She sings in Japanese, English, and French."
)

musicians << Musician.create!(
  user: musician_users[25],
  name: "Ryota Kimura",
  instrument: instruments.sample,
  age: 25,
  styles: "Metal, Shred, Neoclassical",
  location: locations.sample,
  bio: "Ryota's lightning-fast guitar work and neoclassical influences have made him a star in Tokyo's metal scene. He endorses several guitar brands."
)

musicians << Musician.create!(
  user: musician_users[26],
  name: "Ayumi Nakagawa",
  instrument: instruments.sample,
  age: 30,
  styles: "Electronic, Techno, House",
  location: locations.sample,
  bio: "Ayumi is a synth wizard who creates pulsing electronic music. Her DJ sets and live performances are fixtures at Tokyo's best clubs."
)

musicians << Musician.create!(
  user: musician_users[27],
  name: "Kazuki Inoue",
  instrument: instruments.sample,
  age: 33,
  styles: "Jazz, Ska, Reggae",
  location: locations.sample,
  bio: "Kazuki's bright trumpet tone brings joy to every performance. He plays in multiple ska bands and leads jazz jam sessions."
)

musicians << Musician.create!(
  user: musician_users[28],
  name: "Saki Hashimoto",
  instrument: instruments.sample,
  age: 26,
  styles: "Classical, Klezmer, Jazz",
  location: locations.sample,
  bio: "Saki is a versatile clarinetist equally at home in orchestras and klezmer bands. Her warm tone and expressive playing are captivating."
)

musicians << Musician.create!(
  user: musician_users[29],
  name: "Tomoya Saito",
  instrument: instruments.sample,
  age: 35,
  styles: "Latin, Afro-Cuban, Brazilian",
  location: locations.sample,
  bio: "Tomoya specializes in Latin percussion and has studied extensively in Cuba and Brazil. His congas and timbales drive any Latin ensemble."
)

musicians << Musician.create!(
  user: musician_users[30],
  name: "Natsuki Arai",
  instrument: instruments.sample,
  age: 24,
  styles: "Indie, Folk, Alternative",
  location: locations.sample,
  bio: "Natsuki's ethereal voice and introspective lyrics have built a devoted indie following. She writes all her own songs."
)

musicians << Musician.create!(
  user: musician_users[31],
  name: "Haruki Mori",
  instrument: instruments.sample,
  age: 28,
  styles: "Fingerstyle, Folk, Americana",
  location: locations.sample,
  bio: "Haruki's fingerpicking technique is mesmerizing. He performs solo acoustic shows and has released several instrumental albums."
)

musicians << Musician.create!(
  user: musician_users[32],
  name: "Mei Ueno",
  instrument: instruments.sample,
  age: 31,
  styles: "Jazz, Stride, Ragtime",
  location: locations.sample,
  bio: "Mei brings vintage jazz piano styles to modern audiences. Her stride piano playing and ragtime interpretations are energetic and authentic."
)

musicians << Musician.create!(
  user: musician_users[33],
  name: "Kenta Fukuda",
  instrument: instruments.sample,
  age: 27,
  styles: "Pop, Rock, Studio Session",
  location: locations.sample,
  bio: "Kenta is a reliable session drummer with great feel and versatility. He's recorded on numerous J-pop albums and commercial jingles."
)

musicians << Musician.create!(
  user: musician_users[34],
  name: "Nanami Ota",
  instrument: instruments.sample,
  age: 29,
  styles: "Jazz, Fusion, Latin Jazz",
  location: locations.sample,
  bio: "Nanami brings a jazz sensibility to her flute playing. Her improvisations are melodic and her tone is warm and inviting."
)

musicians << Musician.create!(
  user: musician_users[35],
  name: "Yuto Shimizu",
  instrument: instruments.sample,
  age: 34,
  styles: "Jazz, Swing, Rockabilly",
  location: locations.sample,
  bio: "Yuto's upright bass playing swings hard. He's a fixture in Tokyo's jazz and rockabilly scenes, known for his walking bass lines."
)

musicians << Musician.create!(
  user: musician_users[36],
  name: "Kokoro Kawai",
  instrument: instruments.sample,
  age: 22,
  styles: "Soul, Gospel, R&B",
  location: locations.sample,
  bio: "Kokoro's powerful voice and gospel roots shine through in every performance. She's considered one of Tokyo's most promising young vocalists."
)

musicians << Musician.create!(
  user: musician_users[37],
  name: "Sota Maeda",
  instrument: instruments.sample,
  age: 30,
  styles: "Country, Bluegrass, Americana",
  location: locations.sample,
  bio: "Sota brings Nashville to Tokyo with his country guitar picking. He leads Tokyo's premier bluegrass band and teaches guitar."
)

musicians << Musician.create!(
  user: musician_users[38],
  name: "Honoka Takeda",
  instrument: instruments.sample,
  age: 26,
  styles: "Classical, String Quartet, Contemporary",
  location: locations.sample,
  bio: "Honoka's viola playing adds depth and warmth to any ensemble. She performs with chamber groups and contemporary music collectives."
)

musicians << Musician.create!(
  user: musician_users[39],
  name: "Kaito Yoshida",
  instrument: instruments.sample,
  age: 28,
  styles: "Smooth Jazz, R&B, Pop",
  location: locations.sample,
  bio: "Kaito's smooth saxophone playing has graced countless recordings. His melodic style is perfect for romantic ballads and chill grooves."
)

musicians << Musician.create!(
  user: musician_users[40],
  name: "Asuka Tanaka",
  instrument: instruments.sample,
  age: 27,
  styles: "Classical, Baroque, Chamber Music",
  location: locations.sample,
  bio: "Asuka is a principal oboist with a major Tokyo orchestra. Her pure tone and musical intelligence make her a sought-after chamber musician."
)

musicians << Musician.create!(
  user: musician_users[41],
  name: "Ren Sasaki",
  instrument: instruments.sample,
  age: 26,
  styles: "Hip Hop, Neo-Soul, R&B",
  location: locations.sample,
  bio: "Ren's pocket drumming is deep and groovy. He's the go-to drummer for Tokyo's hip hop and neo-soul recording sessions."
)

musicians << Musician.create!(
  user: musician_users[42],
  name: "Chiaki Morimoto",
  instrument: instruments.sample,
  age: 30,
  styles: "Jazz, Gypsy Jazz, Swing",
  location: locations.sample,
  bio: "Chiaki's violin playing swings with Stephane Grappelli-inspired elegance. She leads a gypsy jazz quartet that plays weekly at a Shibuya wine bar."
)

musicians << Musician.create!(
  user: musician_users[43],
  name: "Makoto Aoki",
  instrument: instruments.sample,
  age: 32,
  styles: "Jazz, Fusion, Session Work",
  location: locations.sample,
  bio: "Makoto is one of Tokyo's most in-demand session bassists. His versatility and solid time have made him a first-call for recording sessions."
)

musicians << Musician.create!(
  user: musician_users[44],
  name: "Hikari Noguchi",
  instrument: instruments.sample,
  age: 25,
  styles: "Musical Theater, Classical Crossover, Pop",
  location: locations.sample,
  bio: "Hikari's trained soprano voice and theatrical flair have led to roles in major Tokyo musicals. She also records pop ballads."
)

musicians << Musician.create!(
  user: musician_users[45],
  name: "Yusuke Otsuka",
  instrument: instruments.sample,
  age: 29,
  styles: "Jazz, Bossa Nova, Latin",
  location: locations.sample,
  bio: "Yusuke's nylon-string guitar playing is warm and sophisticated. He specializes in bossa nova and performs at intimate jazz venues."
)

musicians << Musician.create!(
  user: musician_users[46],
  name: "Momoka Fujita",
  instrument: instruments.sample,
  age: 27,
  styles: "Funk, Soul, Gospel",
  location: locations.sample,
  bio: "Momoka's Hammond organ and Rhodes playing bring church-trained soul to funk bands. Her gospel roots shine through in every chord."
)

musicians << Musician.create!(
  user: musician_users[47],
  name: "Taiga Hayashi",
  instrument: instruments.sample,
  age: 31,
  styles: "Jazz, Big Band, Ska",
  location: locations.sample,
  bio: "Taiga's trombone playing is powerful and expressive. He performs with big bands and ska groups, and teaches brass at a local college."
)

musicians << Musician.create!(
  user: musician_users[48],
  name: "Risa Ito",
  instrument: instruments.sample,
  age: 28,
  styles: "Classical, Contemporary, Chamber Music",
  location: locations.sample,
  bio: "Risa brings the bassoon's rich voice to orchestral and chamber settings. She's passionate about contemporary music for bassoon."
)

musicians << Musician.create!(
  user: musician_users[49],
  name: "Hayato Kato",
  instrument: instruments.sample,
  age: 33,
  styles: "Orchestral, Film Scoring, Contemporary",
  location: locations.sample,
  bio: "Hayato is a versatile percussionist who performs with orchestras and records for film scores. His mallet work is particularly acclaimed."
)

musicians << Musician.create!(
  user: musician_users[50],
  name: "Manami Sakamoto",
  instrument: instruments.sample,
  age: 26,
  styles: "Enka, Traditional Japanese, Pop",
  location: locations.sample,
  bio: "Manami's voice carries the emotion of traditional enka while embracing modern pop sensibilities. She performs at festivals and theaters."
)

musicians << Musician.create!(
  user: musician_users[51],
  name: "Shun Watanabe",
  instrument: instruments.sample,
  age: 35,
  styles: "Blues, Delta Blues, Slide Guitar",
  location: locations.sample,
  bio: "Shun is a true blues devotee whose slide guitar playing evokes the Mississippi Delta. He runs blues jams and teaches guitar."
)

musicians << Musician.create!(
  user: musician_users[52],
  name: "Kaori Yamaguchi",
  instrument: instruments.sample,
  age: 33,
  styles: "Classical, Romantic Era, Solo Recital",
  location: locations.sample,
  bio: "Kaori is a concert pianist who specializes in Romantic era repertoire. Her Chopin interpretations have won international competition prizes."
)

musicians << Musician.create!(
  user: musician_users[53],
  name: "Naoto Suzuki",
  instrument: instruments.sample,
  age: 30,
  styles: "Jazz, Bebop, Brush Work",
  location: locations.sample,
  bio: "Naoto's jazz drumming is subtle and swinging. His brush work is particularly admired, and he leads a straight-ahead jazz trio."
)

musicians << Musician.create!(
  user: musician_users[54],
  name: "Yuina Matsumoto",
  instrument: instruments.sample,
  age: 24,
  styles: "Pop, Studio Recording, Commercial",
  location: locations.sample,
  bio: "Yuina's clean flute tone has been featured on numerous pop recordings and TV commercials. She's building a career as a session musician."
)

musicians << Musician.create!(
  user: musician_users[55],
  name: "Riku Takahashi",
  instrument: instruments.sample,
  age: 27,
  styles: "Funk, Slap Bass, Disco",
  location: locations.sample,
  bio: "Riku's slap bass technique is funky and precise. He plays with disco revival bands and modern funk groups around Tokyo."
)

musicians << Musician.create!(
  user: musician_users[56],
  name: "Miyu Yamamoto",
  instrument: instruments.sample,
  age: 21,
  styles: "Anime, J-Pop, Voice Acting",
  location: locations.sample,
  bio: "Miyu is a voice actress and singer whose anime theme songs have gained popularity. Her cute vocal style has a devoted fanbase."
)

musicians << Musician.create!(
  user: musician_users[57],
  name: "Takumi Hasegawa",
  instrument: instruments.sample,
  age: 28,
  styles: "Rock, Hard Rock, Classic Rock",
  location: locations.sample,
  bio: "Takumi's guitar playing channels classic rock heroes. His Les Paul tone and melodic solos anchor several popular Tokyo rock bands."
)

musicians << Musician.create!(
  user: musician_users[58],
  name: "Ai Nomura",
  instrument: instruments.sample,
  age: 29,
  styles: "Contemporary, Experimental, Electronic",
  location: locations.sample,
  bio: "Ai pushes the boundaries of cello with electronics and effects. Her experimental approach has led to collaborations with electronic artists."
)

musicians << Musician.create!(
  user: musician_users[59],
  name: "Keita Yamashita",
  instrument: instruments.sample,
  age: 32,
  styles: "Jazz, Big Band, R&B",
  location: locations.sample,
  bio: "Keita's baritone saxophone provides the low end for big bands and R&B groups. His rich tone and solid time are always in demand."
)

musicians << Musician.create!(
  user: musician_users[60],
  name: "Hinata Koike",
  instrument: instruments.sample,
  age: 27,
  styles: "Classical, Film Scoring, Chamber Music",
  location: locations.sample,
  bio: "Hinata's French horn playing is warm and lyrical. She performs with orchestras and frequently records for film and TV soundtracks."
)

musicians << Musician.create!(
  user: musician_users[61],
  name: "Sora Abe",
  instrument: instruments.sample,
  age: 24,
  styles: "Electronic, EDM, Live Electronic",
  location: locations.sample,
  bio: "Sora combines acoustic drums with electronic pads and triggers. His hybrid drum setup creates unique sounds for electronic music acts."
)

puts "Created #{Musician.count} musicians"

# ===========================================
# BANDS
# ===========================================
puts "Creating bands..."

bands = []

bands << Band.create!(
  user: band_leaders[0],
  name: "Neon Pulse",
  description: "Electronic rock fusion band pushing the boundaries of live electronic music. Combining synthesizers, electric guitars, and programmed beats with raw energy and improvisation.",
  location: "Shibuya, Tokyo"
)
bands[0].genre_list.add("Electronic", "Rock")
bands[0].save!

bands << Band.create!(
  user: band_leaders[1],
  name: "Midnight Jazz Collective",
  description: "Contemporary jazz ensemble exploring the intersection of traditional jazz and modern influences. Known for their late-night sessions and adventurous arrangements.",
  location: "Shinjuku, Tokyo"
)
bands[1].genre_list.add("Jazz")
bands[1].save!

bands << Band.create!(
  user: band_leaders[2],
  name: "Tokyo Thunder",
  description: "High-energy rock band delivering explosive performances. Heavy riffs, thundering drums, and anthemic choruses that shake the walls.",
  location: "Roppongi, Tokyo"
)
bands[2].genre_list.add("Rock")
bands[2].save!

bands << Band.create!(
  user: band_leaders[3],
  name: "Sakura Ensemble",
  description: "Chamber jazz group blending classical instruments with jazz improvisation. Elegant performances that showcase the beauty of acoustic instrumentation.",
  location: "Meguro, Tokyo"
)
bands[3].genre_list.add("Jazz", "Classical")
bands[3].save!

bands << Band.create!(
  user: band_leaders[4],
  name: "Electric Dreams",
  description: "Synthwave and electronic pop group creating retro-futuristic soundscapes. Neon-drenched performances with pulsing beats and soaring melodies.",
  location: "Harajuku, Tokyo"
)
bands[4].genre_list.add("Electronic", "Pop")
bands[4].save!

bands << Band.create!(
  user: band_leaders[5],
  name: "Acoustic Soul",
  description: "Unplugged collective celebrating the warmth of acoustic music. Intimate performances featuring singer-songwriters and folk traditions.",
  location: "Kichijoji, Tokyo"
)
bands[5].genre_list.add("Folk", "Blues")
bands[5].save!

puts "Created #{Band.count} bands"

# ===========================================
# INVOLVEMENTS (Band Members)
# ===========================================
puts "Creating band memberships..."

# Neon Pulse members
Involvement.create!(band: bands[0], musician: musicians[3])  # Takeshi - Guitar
Involvement.create!(band: bands[0], musician: musicians[0])  # Yuki - Drums
Involvement.create!(band: bands[0], musician: musicians[11]) # Emi - Synth

# Midnight Jazz Collective members
Involvement.create!(band: bands[1], musician: musicians[1])  # Kenji - Bass
Involvement.create!(band: bands[1], musician: musicians[2])  # Sakura - Vocals
Involvement.create!(band: bands[1], musician: musicians[0])  # Yuki - Drums
Involvement.create!(band: bands[1], musician: musicians[4])  # Hiroshi - Piano
Involvement.create!(band: bands[1], musician: musicians[5])  # Mika - Sax

# Tokyo Thunder members
Involvement.create!(band: bands[2], musician: musicians[3])  # Takeshi - Guitar
Involvement.create!(band: bands[2], musician: musicians[8])  # Ken - Percussion
Involvement.create!(band: bands[2], musician: musicians[9])  # Yumi - Vocals

# Sakura Ensemble members
Involvement.create!(band: bands[3], musician: musicians[7])  # Aoi - Violin
Involvement.create!(band: bands[3], musician: musicians[4])  # Hiroshi - Piano
Involvement.create!(band: bands[3], musician: musicians[1])  # Kenji - Bass
Involvement.create!(band: bands[3], musician: musicians[6])  # Ryo - Trumpet

# Electric Dreams members
Involvement.create!(band: bands[4], musician: musicians[11]) # Emi - Synth
Involvement.create!(band: bands[4], musician: musicians[0])  # Yuki - Drums
Involvement.create!(band: bands[4], musician: musicians[9])  # Yumi - Vocals

# Acoustic Soul members
Involvement.create!(band: bands[5], musician: musicians[10]) # Daiki - Acoustic Guitar
Involvement.create!(band: bands[5], musician: musicians[2])  # Sakura - Vocals
Involvement.create!(band: bands[5], musician: musicians[7])  # Aoi - Violin

puts "Created #{Involvement.count} band memberships"

# ===========================================
# GIGS
# ===========================================
puts "Creating gigs..."

gigs = []

# Past gigs (completed)
gigs << Gig.create!(
  venue: venues[0],
  name: "Summer Jazz Nights",
  date: 2.weeks.ago,
  start_time: 2.weeks.ago,
  end_time: 2.weeks.ago,
  status: "completed"
)

gigs << Gig.create!(
  venue: venues[1],
  name: "Rock Revolution",
  date: 1.week.ago,
  start_time: 1.week.ago,
  end_time: 1.week.ago,
  status: "completed"
)

gigs << Gig.create!(
  venue: venues[4],
  name: "Osaka Jazz Weekend",
  date: 5.days.ago,
  start_time: 5.days.ago,
  end_time: 5.days.ago,
  status: "completed"
)

# Upcoming gigs (scheduled)
gigs << Gig.create!(
  venue: venues[0],
  name: "Jazz Night Sessions",
  date: 3.days.from_now,
  start_time: 3.days.from_now,
  end_time: 3.days.from_now,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[1],
  name: "Rock Festival 2025",
  date: 1.week.from_now,
  start_time: 1.week.from_now,
  end_time: 1.week.from_now,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[2],
  name: "Electronic Underground",
  date: 10.days.from_now,
  start_time: 10.days.from_now,
  end_time: 10.days.from_now,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[3],
  name: "Indie Showcase",
  date: 2.weeks.from_now,
  start_time: 2.weeks.from_now,
  end_time: 2.weeks.from_now,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[4],
  name: "Billboard Jazz Evening",
  date: 2.weeks.from_now + 2.days,
  start_time: 2.weeks.from_now + 2.days,
  end_time: 2.weeks.from_now + 2.days,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[5],
  name: "Osaka Rock Night",
  date: 3.weeks.from_now,
  start_time: 3.weeks.from_now,
  end_time: 3.weeks.from_now,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[6],
  name: "Kyoto Jazz Evening",
  date: 3.weeks.from_now + 3.days,
  start_time: 3.weeks.from_now + 3.days,
  end_time: 3.weeks.from_now + 3.days,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[7],
  name: "Metro Electronic Night",
  date: 1.month.from_now,
  start_time: 1.month.from_now,
  end_time: 1.month.from_now,
  status: "scheduled"
)

gigs << Gig.create!(
  venue: venues[0],
  name: "New Year Jazz Celebration",
  date: 6.weeks.from_now,
  start_time: 6.weeks.from_now,
  end_time: 6.weeks.from_now,
  status: "scheduled"
)

puts "Created #{Gig.count} gigs"

# ===========================================
# BOOKINGS
# ===========================================
puts "Creating bookings..."

# Past gig bookings (approved/completed)
Booking.create!(band: bands[1], gig: gigs[0], message: "Honored to perform at Summer Jazz Nights!", status: "approved")
Booking.create!(band: bands[3], gig: gigs[0], message: "Sakura Ensemble would love to open the evening.", status: "approved")
Booking.create!(band: bands[2], gig: gigs[1], message: "Tokyo Thunder ready to rock!", status: "approved")
Booking.create!(band: bands[1], gig: gigs[2], message: "Bringing our jazz to Osaka!", status: "approved")

# Upcoming gig bookings (mixed statuses)
Booking.create!(band: bands[1], gig: gigs[3], message: "We'd love to perform at Jazz Night Sessions!", status: "approved")
Booking.create!(band: bands[3], gig: gigs[3], message: "Sakura Ensemble requesting a slot.", status: "pending")

Booking.create!(band: bands[2], gig: gigs[4], message: "Tokyo Thunder is ready for the festival!", status: "approved")
Booking.create!(band: bands[0], gig: gigs[4], message: "Neon Pulse bringing electronic rock energy.", status: "approved")
Booking.create!(band: bands[5], gig: gigs[4], message: "Acoustic Soul for the acoustic stage?", status: "rejected")

Booking.create!(band: bands[0], gig: gigs[5], message: "Perfect venue for our electronic set.", status: "approved")
Booking.create!(band: bands[4], gig: gigs[5], message: "Electric Dreams wants to headline!", status: "pending")

Booking.create!(band: bands[5], gig: gigs[6], message: "Acoustic Soul perfect for indie showcase.", status: "approved")
Booking.create!(band: bands[0], gig: gigs[6], message: "Neon Pulse interested in the showcase.", status: "pending")

Booking.create!(band: bands[1], gig: gigs[7], message: "Midnight Jazz Collective for Billboard!", status: "pending")
Booking.create!(band: bands[3], gig: gigs[7], message: "Sakura Ensemble Osaka debut.", status: "pending")

Booking.create!(band: bands[2], gig: gigs[8], message: "Tokyo Thunder wants to rock Osaka!", status: "approved")

Booking.create!(band: bands[1], gig: gigs[9], message: "Kyoto jazz intimate setting - perfect!", status: "approved")
Booking.create!(band: bands[3], gig: gigs[9], message: "Sakura Ensemble loves Kyoto.", status: "pending")

Booking.create!(band: bands[4], gig: gigs[10], message: "Electric Dreams ready for Metro!", status: "approved")
Booking.create!(band: bands[0], gig: gigs[10], message: "Neon Pulse electronic showcase.", status: "pending")

Booking.create!(band: bands[1], gig: gigs[11], message: "New Year celebration - we're in!", status: "pending")
Booking.create!(band: bands[3], gig: gigs[11], message: "Sakura Ensemble New Year special.", status: "pending")

puts "Created #{Booking.count} bookings"

# ===========================================
# KANBAN TASKS
# ===========================================
puts "Creating kanban tasks..."

# Neon Pulse tasks (created by band leader)
KanbanTask.create!(
  name: "Finalize setlist for Rock Festival",
  status: "in_progress",
  created_by: band_leaders[0],
  task_type: "arrangement",
  deadline: 5.days.from_now,
  description: "Need to finalize the 45-minute setlist for the festival. Include 2 new songs.",
  position: 1
)

KanbanTask.create!(
  name: "Book rehearsal space",
  status: "done",
  created_by: band_leaders[0],
  task_type: "booking",
  deadline: 2.days.ago,
  description: "Studio B at Sound Factory - confirmed for Thursday 7pm",
  position: 2
)

KanbanTask.create!(
  name: "Fix guitar amp feedback issue",
  status: "to_do",
  created_by: band_leaders[0],
  task_type: "equipment",
  deadline: 4.days.from_now,
  description: "Takeshi's amp has feedback at high volumes. Need to troubleshoot.",
  position: 3
)

KanbanTask.create!(
  name: "Design new merchandise",
  status: "to_do",
  created_by: band_leaders[0],
  task_type: "promotion",
  deadline: 2.weeks.from_now,
  description: "T-shirts and stickers for festival sales booth.",
  position: 4
)

# Midnight Jazz Collective tasks (created by band leader)
KanbanTask.create!(
  name: "Arrange 'Midnight in Tokyo'",
  status: "review",
  created_by: band_leaders[1],
  task_type: "arrangement",
  deadline: 2.days.from_now,
  description: "New arrangement with extended sax solo section. Hiroshi reviewing piano parts.",
  position: 1
)

KanbanTask.create!(
  name: "Record demo for Blue Note",
  status: "in_progress",
  created_by: band_leaders[1],
  task_type: "recording",
  deadline: 1.week.from_now,
  description: "3-track demo for potential residency at Blue Note. Studio session booked.",
  position: 2
)

KanbanTask.create!(
  name: "Update press kit photos",
  status: "to_do",
  created_by: band_leaders[1],
  task_type: "promotion",
  deadline: 3.weeks.from_now,
  description: "Schedule photo shoot with all members. Need high-res images for venues.",
  position: 3
)

KanbanTask.create!(
  name: "Rehearse Coltrane medley",
  status: "done",
  created_by: band_leaders[1],
  task_type: "rehearsal",
  deadline: 1.day.ago,
  description: "15-minute Coltrane tribute medley - all parts learned and rehearsed.",
  position: 4
)

# Tokyo Thunder tasks (created by band leader)
KanbanTask.create!(
  name: "Write lyrics for new single",
  status: "in_progress",
  created_by: band_leaders[2],
  task_type: "lyrics",
  deadline: 1.week.from_now,
  description: "Working title: 'Storm Warning'. Need verse 2 and bridge.",
  position: 1
)

KanbanTask.create!(
  name: "Mix festival recording",
  status: "to_do",
  created_by: band_leaders[2],
  task_type: "mixing",
  deadline: 3.weeks.from_now,
  description: "Live recording from last week's show. For YouTube release.",
  position: 2
)

KanbanTask.create!(
  name: "Replace drum heads",
  status: "done",
  created_by: band_leaders[2],
  task_type: "equipment",
  deadline: 3.days.ago,
  description: "New Remo heads installed. Sounds much better!",
  position: 3
)

# Sakura Ensemble tasks (created by band leader)
KanbanTask.create!(
  name: "Compose original piece",
  status: "in_progress",
  created_by: band_leaders[3],
  task_type: "composition",
  deadline: 1.month.from_now,
  description: "Chamber jazz piece featuring violin and trumpet dialogue. Working title: 'Cherry Blossom Waltz'",
  position: 1
)

KanbanTask.create!(
  name: "Contact Kyoto venue",
  status: "done",
  created_by: band_leaders[3],
  task_type: "booking",
  deadline: 1.week.ago,
  description: "Yamatoya confirmed for our Kyoto debut!",
  position: 2
)

# Electric Dreams tasks (created by band leader)
KanbanTask.create!(
  name: "Program new synth patches",
  status: "in_progress",
  created_by: band_leaders[4],
  task_type: "composition",
  deadline: 1.week.from_now,
  description: "80s-inspired patches for the Metro show. Emi working on modular sequences.",
  position: 1
)

KanbanTask.create!(
  name: "Design visuals for live show",
  status: "to_do",
  created_by: band_leaders[4],
  task_type: "promotion",
  deadline: 3.weeks.from_now,
  description: "Projection mapped visuals synced to our set. Need to find VJ.",
  position: 2
)

# Acoustic Soul tasks (created by band leader)
KanbanTask.create!(
  name: "Learn new folk covers",
  status: "in_progress",
  created_by: band_leaders[5],
  task_type: "rehearsal",
  deadline: 10.days.from_now,
  description: "Adding 3 classic folk songs to our repertoire for indie showcase.",
  position: 1
)

KanbanTask.create!(
  name: "Record acoustic EP",
  status: "to_do",
  created_by: band_leaders[5],
  task_type: "recording",
  deadline: 2.months.from_now,
  description: "5-track EP recorded live in studio. Simple, warm production.",
  position: 2
)

puts "Created #{KanbanTask.count} kanban tasks"

# ===========================================
# MESSAGES
# ===========================================
puts "Creating chat messages..."

# Neon Pulse chat
chat1 = bands[0].chat
Message.create!(chat: chat1, user: band_leaders[0], content: "Hey everyone! Rehearsal confirmed for Thursday at 7pm. Studio B at Sound Factory.")
Message.create!(chat: chat1, user: musicians[3].user, content: "Perfect, I'll bring the new pedal board. Been tweaking the distortion settings.")
Message.create!(chat: chat1, user: musicians[0].user, content: "Can we work on the tempo for 'Electric Dreams'? I think we should push it a bit faster.")
Message.create!(chat: chat1, user: musicians[11].user, content: "I've got some new synth patches ready to try out. Very 80s vibes!")
Message.create!(chat: chat1, user: band_leaders[0], content: "Love it! Let's run through the full festival set at least twice.")
Message.create!(chat: chat1, user: musicians[3].user, content: "Should we add the new song we've been working on?")
Message.create!(chat: chat1, user: band_leaders[0], content: "Yes! Let's debut it at the festival. Perfect opportunity.")

# Midnight Jazz Collective chat
chat2 = bands[1].chat
Message.create!(chat: chat2, user: band_leaders[1], content: "Great news everyone! Jazz Night Sessions is confirmed!")
Message.create!(chat: chat2, user: musicians[2].user, content: "Amazing! What songs are we doing for the set?")
Message.create!(chat: chat2, user: musicians[1].user, content: "I suggest we open with 'Midnight in Tokyo' - it always gets the crowd going.")
Message.create!(chat: chat2, user: musicians[4].user, content: "I've been working on a new arrangement with an extended piano intro. Thoughts?")
Message.create!(chat: chat2, user: musicians[5].user, content: "Would love a longer sax solo section in the middle!")
Message.create!(chat: chat2, user: band_leaders[1], content: "Let's try both ideas at rehearsal tomorrow. We have 2 hours booked.")
Message.create!(chat: chat2, user: musicians[0].user, content: "I'll bring brushes and sticks - not sure which vibe we're going for yet.")
Message.create!(chat: chat2, user: musicians[2].user, content: "Maybe we could do a ballad section in the middle of the set?")
Message.create!(chat: chat2, user: band_leaders[1], content: "Perfect. I'm thinking: uptempo opener, ballad, Coltrane medley, original, big finish.")

# Tokyo Thunder chat
chat3 = bands[2].chat
Message.create!(chat: chat3, user: band_leaders[2], content: "ROCK FESTIVAL CONFIRMED! Let's crush it!")
Message.create!(chat: chat3, user: musicians[3].user, content: "YES! Time to bring the thunder!")
Message.create!(chat: chat3, user: musicians[9].user, content: "I've been practicing my screams. My neighbors hate me now lol")
Message.create!(chat: chat3, user: musicians[8].user, content: "I ordered new drum heads. Should arrive tomorrow.")
Message.create!(chat: chat3, user: band_leaders[2], content: "Perfect timing. Old ones were getting dented. Extra rehearsal Sunday?")
Message.create!(chat: chat3, user: musicians[3].user, content: "I'm in. Let's nail that breakdown in 'Storm Warning'.")

# Sakura Ensemble chat
chat4 = bands[3].chat
Message.create!(chat: chat4, user: band_leaders[3], content: "Kyoto Jazz Spot confirmed us for a show! Their first chamber jazz night.")
Message.create!(chat: chat4, user: musicians[7].user, content: "I've always wanted to play there! Such a beautiful venue.")
Message.create!(chat: chat4, user: musicians[4].user, content: "The machiya acoustics will be perfect for our sound.")
Message.create!(chat: chat4, user: musicians[6].user, content: "Should I bring the flugelhorn as well? Might suit the intimate space.")
Message.create!(chat: chat4, user: musicians[1].user, content: "Definitely! And I'll bring the upright bass instead of electric.")
Message.create!(chat: chat4, user: band_leaders[3], content: "Agreed. Let's keep it fully acoustic for this one.")

# Electric Dreams chat
chat5 = bands[4].chat
Message.create!(chat: chat5, user: band_leaders[4], content: "Metro Kyoto is going to be incredible. Their sound system is legendary.")
Message.create!(chat: chat5, user: musicians[11].user, content: "I've been programming new patches all week. The modular is sounding massive!")
Message.create!(chat: chat5, user: musicians[0].user, content: "Should we add more live drums or keep it more electronic?")
Message.create!(chat: chat5, user: musicians[9].user, content: "I vote hybrid - live drums on the drops, programmed for the verses.")
Message.create!(chat: chat5, user: band_leaders[4], content: "Love that idea. Let's work on the transitions at rehearsal.")
Message.create!(chat: chat5, user: musicians[11].user, content: "I'll prepare some transition patches. Thinking long reverb tails...")

# Acoustic Soul chat
chat6 = bands[5].chat
Message.create!(chat: chat6, user: band_leaders[5], content: "Indie Showcase is our chance to reach a new audience!")
Message.create!(chat: chat6, user: musicians[10].user, content: "I've been learning some Joni Mitchell covers. Might fit the vibe?")
Message.create!(chat: chat6, user: musicians[2].user, content: "Perfect! I know all her songs. Let's do 'Both Sides Now'.")
Message.create!(chat: chat6, user: musicians[7].user, content: "I can add some subtle violin harmonies. Keep it gentle.")
Message.create!(chat: chat6, user: band_leaders[5], content: "That's exactly what I was hoping for. Intimate and warm.")
Message.create!(chat: chat6, user: musicians[10].user, content: "Should we do a full acoustic set or include some originals?")
Message.create!(chat: chat6, user: band_leaders[5], content: "Let's do 50/50. Covers to hook them, originals to show who we are.")

puts "Created #{Message.count} messages"

# ===========================================
# BAND INVITATIONS
# ===========================================
puts "Creating band invitations..."

# Pending invitations
BandInvitation.create!(
  band: bands[0],
  musician: musicians[4],
  inviter: band_leaders[0],
  status: "Pending"
)

BandInvitation.create!(
  band: bands[1],
  musician: musicians[6],
  inviter: band_leaders[1],
  status: "Pending"
)

BandInvitation.create!(
  band: bands[2],
  musician: musicians[1],
  inviter: band_leaders[2],
  status: "Pending"
)

BandInvitation.create!(
  band: bands[4],
  musician: musicians[4],
  inviter: band_leaders[4],
  status: "Pending"
)

# Accepted invitations (historical)
BandInvitation.create!(
  band: bands[0],
  musician: musicians[3],
  inviter: band_leaders[0],
  status: "Accepted"
)

BandInvitation.create!(
  band: bands[1],
  musician: musicians[2],
  inviter: band_leaders[1],
  status: "Accepted"
)

# Declined invitations
BandInvitation.create!(
  band: bands[2],
  musician: musicians[5],
  inviter: band_leaders[2],
  status: "Declined"
)

BandInvitation.create!(
  band: bands[3],
  musician: musicians[3],
  inviter: band_leaders[3],
  status: "Declined"
)

puts "Created #{BandInvitation.count} band invitations"

# ===========================================
# NOTIFICATIONS
# ===========================================
puts "Creating notifications..."

# Band invitation notifications
Notification.create!(
  user: musicians[4].user,
  notifiable: BandInvitation.find_by(band: bands[0], musician: musicians[4]),
  notification_type: "band_invitation",
  message: "Neon Pulse has invited you to join the band!",
  read: false,
  actor: band_leaders[0]
)

Notification.create!(
  user: musicians[6].user,
  notifiable: BandInvitation.find_by(band: bands[1], musician: musicians[6]),
  notification_type: "band_invitation",
  message: "Midnight Jazz Collective has invited you to join the band!",
  read: false,
  actor: band_leaders[1]
)

Notification.create!(
  user: musicians[1].user,
  notifiable: BandInvitation.find_by(band: bands[2], musician: musicians[1]),
  notification_type: "band_invitation",
  message: "Tokyo Thunder has invited you to join the band!",
  read: true,
  actor: band_leaders[2]
)

# Band message notifications (unread)
Notification.create!(
  user: musicians[3].user,
  notifiable: bands[0].chat.messages.last,
  notification_type: "band_message",
  message: "New message in Neon Pulse chat",
  read: false,
  actor: band_leaders[0]
)

Notification.create!(
  user: musicians[2].user,
  notifiable: bands[1].chat.messages.last,
  notification_type: "band_message",
  message: "New message in Midnight Jazz Collective chat",
  read: false,
  actor: band_leaders[1]
)

# Member joined notifications
Notification.create!(
  user: band_leaders[0],
  notifiable: bands[0],
  notification_type: "band_member_joined",
  message: "Takeshi Ito has joined Neon Pulse!",
  read: true,
  actor: musicians[3].user
)

Notification.create!(
  user: band_leaders[1],
  notifiable: bands[1],
  notification_type: "band_member_joined",
  message: "Mika Yoshida has joined Midnight Jazz Collective!",
  read: true,
  actor: musicians[5].user
)

# Invitation accepted notifications
Notification.create!(
  user: band_leaders[0],
  notifiable: BandInvitation.find_by(band: bands[0], musician: musicians[3]),
  notification_type: "band_invitation_accepted",
  message: "Takeshi Ito accepted your invitation to Neon Pulse!",
  read: true,
  actor: musicians[3].user
)

# Invitation declined notifications
Notification.create!(
  user: band_leaders[2],
  notifiable: BandInvitation.find_by(band: bands[2], musician: musicians[5]),
  notification_type: "band_invitation_declined",
  message: "Mika Yoshida declined your invitation to Tokyo Thunder",
  read: false,
  actor: musicians[5].user
)

puts "Created #{Notification.count} notifications"

# ===========================================
# DIRECT MESSAGES
# ===========================================
puts "Creating direct message chats..."

# DM between two musicians discussing collaboration
dm1 = Chat.between(musicians[3].user, musicians[0].user)
Message.create!(chat: dm1, user: musicians[3].user, content: "Hey Yuki! Loved your drumming at last week's show.")
Message.create!(chat: dm1, user: musicians[0].user, content: "Thanks Takeshi! Your guitar tone was incredible. What pedals are you using?")
Message.create!(chat: dm1, user: musicians[3].user, content: "Mix of analog and digital - Boss DS-1 into a Strymon Timeline. Want to jam sometime?")
Message.create!(chat: dm1, user: musicians[0].user, content: "Definitely! I'm free Wednesdays usually.")

# DM between band leader and venue owner about booking
dm2 = Chat.between(band_leaders[1], venue_owners[0])
Message.create!(chat: dm2, user: band_leaders[1], content: "Hi! I'm the leader of Midnight Jazz Collective. We're interested in a residency at Blue Note.")
Message.create!(chat: dm2, user: venue_owners[0], content: "Hello! I've seen your group perform - very impressive. What were you thinking?")
Message.create!(chat: dm2, user: band_leaders[1], content: "We'd love to do a monthly late-night session. First Thursday of each month?")
Message.create!(chat: dm2, user: venue_owners[0], content: "That could work! Let's discuss details. Can you send me a press kit?")
Message.create!(chat: dm2, user: band_leaders[1], content: "Will do! I'll send it over this week. Thank you for considering us!")

# DM between musicians about joining a band
dm3 = Chat.between(musicians[4].user, band_leaders[0])
Message.create!(chat: dm3, user: band_leaders[0], content: "Hey Hiroshi! I've been following your work. Your keyboard playing is amazing.")
Message.create!(chat: dm3, user: musicians[4].user, content: "Thank you! I really enjoy Neon Pulse's sound. Very unique.")
Message.create!(chat: dm3, user: band_leaders[0], content: "We could use your skills. Would you be interested in joining us for some shows?")
Message.create!(chat: dm3, user: musicians[4].user, content: "I'm intrigued! What kind of keyboard parts are you looking for?")
Message.create!(chat: dm3, user: band_leaders[0], content: "Synth pads and some piano fills. Very 80s synthwave inspired. I'll send you an invite!")

puts "Created #{Chat.direct_messages.count} direct message conversations"

puts ""
puts "=" * 50
puts "SEED COMPLETE!"
puts "=" * 50
puts ""
puts "Summary:"
puts "  Users: #{User.count}"
puts "    - Venue Owners: #{User.where(user_type: 'venue').count}"
puts "    - Musicians: #{User.where(user_type: 'musician').count}"
puts "    - Band Leaders: #{User.where(user_type: 'band').count}"
puts "  Musicians: #{Musician.count}"
puts "  Bands: #{Band.count}"
puts "  Band Memberships: #{Involvement.count}"
puts "  Venues: #{Venue.count}"
puts "  Gigs: #{Gig.count}"
puts "  Bookings: #{Booking.count}"
puts "  Kanban Tasks: #{KanbanTask.count}"
puts "  Chats: #{Chat.count}"
puts "    - Band Chats: #{Chat.band_chats.count}"
puts "    - Direct Messages: #{Chat.direct_messages.count}"
puts "  Messages: #{Message.count}"
puts "  Band Invitations: #{BandInvitation.count}"
puts "  Notifications: #{Notification.count}"
puts ""
puts "Test accounts (all passwords: 'password123'):"
puts "  Venue Owner: bluenote@venue.com"
puts "  Musician: yuki.drums@musician.com"
puts "  Band Leader: neon@band.com"
puts ""
