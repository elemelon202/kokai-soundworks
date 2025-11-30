# MAINSTAGE & Engagement Features

## Overview

MAINSTAGE is a weekly contest that showcases artists with the highest overall engagement on the platform. Unlike simple "most liked video" contests, MAINSTAGE rewards musicians and bands who build genuine connections across the entire site.

This document also covers the engagement features needed to drive traffic from fans (not just musicians) and create a thriving community.

---

# 📊 IMPLEMENTATION STATUS SUMMARY

*Last updated: December 2025*

## ✅ COMPLETED FEATURES (20/24 core features - 83%)

| Feature | Status | Notes |
|---------|--------|-------|
| Follow System | ✅ COMPLETE | Polymorphic for musicians & bands |
| Profile View Tracking | ✅ COMPLETE | With IP hashing for anonymous |
| Profile Saves/Bookmarks | ✅ COMPLETE | Polymorphic saves |
| Spotify/Music Embeds | ✅ COMPLETE | Full oEmbed integration |
| Endorsements | ✅ COMPLETE | 15 skill types, MAINSTAGE scoring |
| Shoutouts | ✅ COMPLETE | With notifications |
| Challenge/Duet System | ✅ COMPLETE | Full workflow with voting |
| Owner Dashboard | ✅ COMPLETE | Analytics in edit pages |
| Fan Accounts | ✅ COMPLETE | User types (musician, band_leader, fan) |
| MAINSTAGE (Musicians) | ✅ COMPLETE | Weekly contests with anti-gaming |
| MAINSTAGE (Bands) | ✅ COMPLETE | Separate band contests |
| Notifications | ✅ COMPLETE | 16+ types, ActionCable |
| Direct Messages | ✅ COMPLETE | 1:1 and band chats |
| Posts/Feed | ✅ COMPLETE | Personal and band posts |
| Reposts | ✅ COMPLETE | Share posts to followers |
| Fan-to-Fan Friendships | ✅ COMPLETE | Request/accept workflow |
| Activity Tracking | ✅ COMPLETE | Polymorphic activities |
| Musician Shorts | ✅ COMPLETE | Video uploads with likes/comments |
| Short Likes & Comments | ✅ COMPLETE | Engagement tracking |
| Post Comments & Likes | ✅ COMPLETE | Feed engagement |

## 🚧 NOT YET IMPLEMENTED (4 features)

| Feature | Status | Priority |
|---------|--------|----------|
| Gig Check-ins | ❌ NOT STARTED | High - Part 10 |
| Fan Points System | ❌ NOT STARTED | Medium - Part 2 |
| Groups/Communities | ❌ NOT STARTED | Low - Part 6 |
| Industry Accounts | ❌ NOT STARTED | Low - Part 7 |

## 📋 FUTURE FEATURES (Not Started)

| Feature | Part | Status |
|---------|------|--------|
| Setlist Requests | Part 2 | ❌ NOT STARTED |
| Merch Store | Part 2 | ❌ NOT STARTED |
| Advanced Reactions | Part 6 | ❌ NOT STARTED |
| Real-World Check-ins | Part 10 | ❌ NOT STARTED |
| Extended Real-World Features | Part 11 | ❌ NOT STARTED |
| Monetization/Subscriptions | Part 12 | ❌ NOT STARTED |

---

# Part 1: Engagement Features

## 1.1 Follow System ✅ COMPLETE

Allow users to follow musicians and bands.

### Database

#### `follows`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| follower_id | bigint | User who is following |
| followable_type | string | `Musician` or `Band` |
| followable_id | bigint | ID of musician/band being followed |
| created_at | datetime | |

**Indexes:** Unique on `[follower_id, followable_type, followable_id]`

### Model

```ruby
class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followable, polymorphic: true

  validates :follower_id, uniqueness: { scope: [:followable_type, :followable_id] }
end

# In Musician/Band models
has_many :follows, as: :followable, dependent: :destroy
has_many :followers, through: :follows, source: :follower

# In User model
has_many :follows, foreign_key: :follower_id, dependent: :destroy
has_many :followed_musicians, through: :follows, source: :followable, source_type: 'Musician'
has_many :followed_bands, through: :follows, source: :followable, source_type: 'Band'
```

### Routes

```ruby
resources :musicians do
  member do
    post :follow
    delete :unfollow
  end
end

resources :bands do
  member do
    post :follow
    delete :unfollow
  end
end
```

---

## 1.2 Profile View Tracking ✅ COMPLETE

Track unique profile visits per week (private to profile owner).

### Database

#### `profile_views`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| viewer_id | bigint | User who viewed (nullable for anonymous) |
| viewable_type | string | `Musician` or `Band` |
| viewable_id | bigint | Profile being viewed |
| viewed_at | datetime | |
| ip_hash | string | Hashed IP for anonymous deduplication |

**Indexes:** Index on `[viewable_type, viewable_id, viewed_at]`

### Implementation

```ruby
# In show action
def show
  @musician = Musician.find(params[:id])
  track_profile_view(@musician) unless owner?(@musician)
end

private

def track_profile_view(profile)
  ProfileView.create(
    viewer: current_user,
    viewable: profile,
    viewed_at: Time.current,
    ip_hash: current_user ? nil : Digest::SHA256.hexdigest(request.remote_ip)
  )
end
```

### Dashboard Display (Owner Only)

```ruby
# In dashboard
@weekly_views = @musician.profile_views
                         .where(viewed_at: 1.week.ago..)
                         .distinct
                         .count(:viewer_id)
```

---

## 1.3 Profile Saves/Bookmarks ✅ COMPLETE

Let users save profiles for later.

### Database

#### `profile_saves`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | User saving the profile |
| saveable_type | string | `Musician` or `Band` |
| saveable_id | bigint | Profile being saved |
| created_at | datetime | |

### User Interface

- Bookmark icon on profile pages
- "Saved Profiles" page in user account
- Count visible only on owner dashboard

---

## 1.4 Spotify/Music Embeds

Embed Spotify players so plays count toward artist's Spotify streams.

### Database

Update existing `spotify_tracks` table or create new one:

#### `music_embeds`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| embeddable_type | string | `Musician` or `Band` |
| embeddable_id | bigint | |
| platform | string | `spotify`, `apple_music`, `soundcloud`, `bandcamp` |
| external_url | string | Original URL |
| embed_html | text | Cached embed code |
| title | string | Track/album name |
| position | integer | Display order |
| created_at | datetime | |

### Spotify oEmbed Integration

```ruby
class SpotifyEmbedService
  OEMBED_URL = "https://open.spotify.com/oembed"

  def self.fetch_embed(spotify_url)
    response = HTTP.get(OEMBED_URL, params: { url: spotify_url })
    data = JSON.parse(response.body)

    {
      embed_html: data['html'],
      title: data['title'],
      thumbnail_url: data['thumbnail_url']
    }
  end
end
```

### Display

```erb
<%# On musician/band profile %>
<% @musician.music_embeds.each do |embed| %>
  <div class="music-embed">
    <%= embed.embed_html.html_safe %>
  </div>
<% end %>
```

---

## 1.5 Endorsements

Musicians can endorse each other's skills.

### Database

#### `endorsements`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| endorser_id | bigint | Musician giving endorsement |
| endorsee_id | bigint | Musician receiving endorsement |
| skill | string | e.g., "Guitar", "Vocals", "Songwriting" |
| message | text | Optional comment |
| created_at | datetime | |

**Constraints:** One endorsement per skill per endorser/endorsee pair

### Display

```erb
<div class="endorsements">
  <h3>Endorsed Skills</h3>
  <% @musician.endorsement_summary.each do |skill, count| %>
    <span class="skill-badge"><%= skill %> (<%= count %>)</span>
  <% end %>
</div>
```

---

## 1.6 Shoutouts

Public appreciation posts on profiles.

### Database

#### `shoutouts`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| author_id | bigint | User giving shoutout |
| recipient_type | string | `Musician` or `Band` |
| recipient_id | bigint | |
| message | text | The shoutout content |
| created_at | datetime | |

### Display

Featured on profile page, limited to recent/top shoutouts.

---

## 1.7 Challenge/Duet System

"I Can Play This Too" battles between musicians.

### Database

#### `challenges`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| creator_id | bigint | Musician who started the challenge |
| original_short_id | bigint | The original short |
| title | string | Challenge name |
| description | text | |
| status | string | `open`, `voting`, `closed` |
| winner_id | bigint | Winning response (nullable) |
| created_at | datetime | |

#### `challenge_responses`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| challenge_id | bigint | |
| musician_short_id | bigint | The response short |
| musician_id | bigint | |
| votes_count | integer | Counter cache |
| created_at | datetime | |

#### `challenge_votes`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| challenge_response_id | bigint | |
| created_at | datetime | |

### Challenge Flow

1. Musician uploads a short and tags it as a "Challenge"
2. Other musicians can "Respond" with their own version
3. Users vote on responses
4. Challenge creator can pick a winner or let votes decide
5. Winners get bonus MAINSTAGE points

### Variations

- **Cover Chain**: Each response adds their instrument
- **Speed Run**: Fastest/cleanest performance wins
- **Genre Flip**: Same piece, different style

---

## 1.8 Owner Dashboard

Private analytics for musicians and bands.

### Routes

```ruby
resources :musicians do
  member do
    get :dashboard  # Only accessible by owner
  end
end

resources :bands do
  member do
    get :dashboard
  end
end
```

### Dashboard Data

```ruby
def dashboard
  @musician = Musician.find(params[:id])
  authorize @musician, :dashboard?

  @stats = {
    profile_views_week: @musician.profile_views.where(viewed_at: 1.week.ago..).count,
    profile_saves: @musician.profile_saves.count,
    new_followers_week: @musician.follows.where(created_at: 1.week.ago..).count,
    total_followers: @musician.follows.count,
    shorts_engagement: calculate_shorts_engagement(@musician),
    mainstage_rank: calculate_current_rank(@musician),
    endorsements_received: @musician.endorsements_received.count
  }
end
```

### Dashboard View

```
┌─────────────────────────────────────────────────────────────┐
│  📊 YOUR DASHBOARD                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  This Week                                                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Profile Views│ │ New Followers│ │ Profile Saves│        │
│  │     247      │ │      18      │ │      32      │        │
│  │   ↑ 23%      │ │    ↑ 12%     │ │    ↑ 8%      │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│                                                             │
│  MAINSTAGE Status                                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Current Rank: #7                                   │   │
│  │  Points This Week: 156                              │   │
│  │  [View Leaderboard]                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Top Performing Shorts                                      │
│  1. "Jazz Improv Session" - 45 likes, 23 comments          │
│  2. "Funk Bass Line" - 38 likes, 19 comments               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# Part 2: Fan Engagement & Monetization

## 2.1 Fan Accounts

Not everyone on the platform needs to be a musician. Fan accounts drive traffic.

### User Roles

```ruby
# Add to users table
add_column :users, :role, :string, default: 'fan'
# Roles: 'fan', 'musician', 'venue', 'admin'
```

### Fan Capabilities

- Follow musicians and bands
- Like and comment on shorts
- Vote in challenges
- Save/bookmark profiles
- Attend gigs (check-ins)
- Request setlist songs
- Purchase merch
- Share profiles externally

### Fan Profile (Simplified)

- Display name
- Avatar
- Favorite genres
- Location
- List of followed artists
- Gigs attended

---

## 2.2 Gig Check-ins

Fans mark that they attended a gig.

### Database

#### `gig_checkins`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Fan checking in |
| gig_id | bigint | |
| checked_in_at | datetime | |
| photo | attachment | Optional photo from the gig |

### Display

- "X fans attended this gig"
- "This band has been seen by X fans"
- Fan profile shows gigs attended

---

## 2.3 Setlist Requests

Fans can request songs for upcoming gigs.

### Database

#### `setlist_requests`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Fan requesting |
| gig_id | bigint | Upcoming gig |
| song_title | string | |
| votes_count | integer | Counter cache |
| created_at | datetime | |

#### `setlist_votes`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| setlist_request_id | bigint | |

### Flow

1. Fan requests a song for an upcoming gig
2. Other fans vote on requests
3. Band sees top requests on their dashboard
4. Band can mark songs as "Added to setlist"

---

## 2.4 Merch Store

Sell band merchandise through the platform.

### Database

#### `merch_items`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| band_id | bigint | |
| name | string | |
| description | text | |
| price_cents | integer | Price in cents |
| images | attachments | Product photos |
| variants | jsonb | Size/color options |
| inventory_count | integer | |
| status | string | `active`, `sold_out`, `hidden` |

#### `merch_orders`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Buyer |
| band_id | bigint | |
| status | string | `pending`, `paid`, `shipped`, `delivered` |
| total_cents | integer | |
| shipping_address | jsonb | |
| stripe_payment_id | string | |
| created_at | datetime | |

#### `merch_order_items`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| merch_order_id | bigint | |
| merch_item_id | bigint | |
| variant | jsonb | Selected options |
| quantity | integer | |
| price_cents | integer | Price at time of purchase |

### Integration Options

**Option A: Native Store**
- Full checkout on Kokai
- Stripe Connect for payouts to bands
- Platform takes small commission (5-10%)

**Option B: External Links**
- Link to band's existing store (Bandcamp, BigCartel, etc.)
- Track clicks for engagement scoring
- No commission but less integration

**Recommendation:** Start with Option B, graduate to Option A as platform grows.

---

## 2.5 Fan Rewards / Loyalty

Give fans reasons to keep coming back.

### Fan Points System

| Action | Points |
|--------|--------|
| Daily login | 5 |
| Like a short | 1 |
| Comment on a short | 3 |
| Follow an artist | 5 |
| Attend a gig (check-in) | 20 |
| Vote in a challenge | 2 |
| Share a profile externally | 10 |
| Refer a new user | 50 |

### Rewards

- **Badges**: "Super Fan", "Gig Goer", "Early Supporter"
- **Exclusive Content**: Access to artist Q&As, behind-the-scenes
- **Merch Discounts**: Redeem points for discount codes
- **Priority Access**: Early ticket sales for gigs
- **Leaderboard**: Top fans featured on site

### Database

#### `fan_points`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| points | integer | Current balance |
| lifetime_points | integer | Total earned |
| level | integer | Fan level |

#### `point_transactions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| amount | integer | Points earned/spent |
| action | string | What triggered it |
| created_at | datetime | |

---

## 2.6 External Sharing & Referrals

Track when profiles are shared and reward referrals.

### Shareable Links

```ruby
# Generate trackable share URL
def share_url(profile)
  "#{root_url}#{profile.path}?ref=#{current_user&.referral_code}"
end
```

### Database

#### `share_clicks`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| sharer_id | bigint | User who shared |
| shareable_type | string | `Musician`, `Band`, `MusicianShort` |
| shareable_id | bigint | |
| platform | string | `twitter`, `facebook`, `copy`, etc. |
| clicked_at | datetime | |
| converted | boolean | Did visitor sign up? |

### Referral System

- Each user gets a unique referral code
- When someone signs up via referral:
  - Referrer gets 50 points
  - New user gets 25 bonus points
  - Track in `point_transactions`

---

## 2.7 Embeddable Profile Widgets

Let musicians embed mini-profiles on their own websites.

### Widget Code

```ruby
# Generate embed code
def widget_embed_code(musician)
  "<iframe src='#{widget_url(musician)}' width='300' height='400' frameborder='0'></iframe>"
end
```

### Widget Page

Stripped-down profile showing:
- Avatar
- Name & instrument
- Follow button (links to full profile)
- Latest short (auto-playing)
- "View on Kokai" link

### Tracking

- Track widget impressions
- Track clicks through to full profile
- Attribute as engagement for MAINSTAGE

---

# Part 3: MAINSTAGE Scoring (Revised)

## 3.1 Holistic Engagement Score

MAINSTAGE now considers ALL engagement, not just shorts.

### Weekly Score Calculation

| Metric | Points |
|--------|--------|
| New follower | 5 |
| Profile view | 1 |
| Profile save | 3 |
| Short like | 2 |
| Short comment | 4 |
| Endorsement received | 10 |
| Shoutout received | 8 |
| Message received | 3 |
| External share click | 5 |
| Challenge response received | 15 |
| Challenge vote received | 2 |
| Gig check-in (for bands) | 5 |
| Merch interest click | 3 |

### Score Service

```ruby
class MainstageScoreCalculator
  WEIGHTS = {
    follow: 5,
    profile_view: 1,
    profile_save: 3,
    short_like: 2,
    short_comment: 4,
    endorsement: 10,
    shoutout: 8,
    message: 3,
    share_click: 5,
    challenge_response: 15,
    challenge_vote: 2,
    gig_checkin: 5,
    merch_click: 3
  }.freeze

  def calculate_weekly_score(musician, week_start, week_end)
    score = 0
    date_range = week_start..week_end

    score += musician.follows.where(created_at: date_range).count * WEIGHTS[:follow]
    score += musician.profile_views.where(viewed_at: date_range).count * WEIGHTS[:profile_view]
    score += musician.profile_saves.where(created_at: date_range).count * WEIGHTS[:profile_save]

    musician.musician_shorts.each do |short|
      score += short.short_likes.where(created_at: date_range).count * WEIGHTS[:short_like]
      score += short.short_comments.where(created_at: date_range).count * WEIGHTS[:short_comment]
    end

    score += musician.endorsements_received.where(created_at: date_range).count * WEIGHTS[:endorsement]
    score += musician.shoutouts_received.where(created_at: date_range).count * WEIGHTS[:shoutout]
    # ... etc

    score
  end
end
```

---

## 3.2 Separate Categories

As platform grows, consider separate MAINSTAGE categories:

- **Musicians MAINSTAGE**: Individual artists
- **Bands MAINSTAGE**: Full bands
- **Challenge Champions**: Best challenge performances
- **Rising Stars**: Accounts under 30 days old
- **Fan Favorites**: Most followed this week

---

## 3.3 Updated Database Schema

#### `mainstage_weeks`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| week_start | date | Sunday start date |
| week_end | date | Saturday end date |
| status | string | `active`, `calculating`, `finalized` |
| created_at | datetime | |
| updated_at | datetime | |

#### `mainstage_winners`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| mainstage_week_id | bigint | |
| winnable_type | string | `Musician` or `Band` |
| winnable_id | bigint | |
| category | string | `musician`, `band`, `challenge`, `rising` |
| position | string | `headliner` or `opening_act` |
| rank | integer | 1 for headliner, 2-6 for opening acts |
| total_score | integer | |
| score_breakdown | jsonb | Detailed breakdown by metric |
| created_at | datetime | |

---

# Part 4: Implementation Phases

## Phase 1: Foundation (Week 1-2)
1. Follow system (polymorphic)
2. Profile view tracking
3. Profile saves/bookmarks
4. Owner dashboard (basic)

## Phase 2: Music & Content (Week 3-4)
5. Spotify/music embeds
6. Endorsements system
7. Shoutouts
8. Enhanced dashboard with stats

## Phase 3: Fan Features (Week 5-6)
9. Fan account role
10. Gig check-ins
11. Setlist requests
12. Fan points system (basic)

## Phase 4: Challenges & Viral (Week 7-8)
13. Challenge/duet system
14. Challenge voting
15. Share tracking
16. Referral system

## Phase 5: MAINSTAGE (Week 9-10)
17. MAINSTAGE scoring with all metrics
18. MAINSTAGE page and hall of fame
19. Winner notifications
20. Profile badges

## Phase 6: Monetization (Week 11-12)
21. Merch store (links first, native later)
22. Fan rewards redemption
23. Embeddable widgets
24. External traffic tracking

---

# Part 5: Traffic Growth Strategy

## Organic Growth Drivers

1. **Shareable Content**
   - Challenge battles are inherently viral
   - Winner announcements are share-worthy
   - Embeddable widgets spread the brand

2. **Network Effects**
   - Musicians invite their fans
   - Fans follow multiple artists
   - Bands invite their members

3. **SEO**
   - Public profile pages are indexable
   - Challenge pages rank for song names
   - Local SEO for gigs and venues

4. **Email Re-engagement**
   - Weekly digest of followed artists
   - MAINSTAGE results
   - Challenge notifications

## Metrics to Track

- Daily/Weekly/Monthly Active Users
- Fan:Musician ratio
- Follows per user
- Shares per profile
- Referral conversion rate
- Time on site
- Return visit rate

---

# Appendix: ASCII Mockups

## Fan Profile Page

```
┌─────────────────────────────────────────────────────────────┐
│  [Avatar]  JaneDoe                                          │
│            Music Fan • Los Angeles                          │
│            Joined Nov 2025                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🎵 Following (24)              🎫 Gigs Attended (7)        │
│                                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                       │
│  │ Artist  │ │ Artist  │ │ Band    │  [View All]           │
│  └─────────┘ └─────────┘ └─────────┘                       │
│                                                             │
│  🏆 Badges                                                  │
│  [Super Fan] [Early Adopter] [Gig Goer]                    │
│                                                             │
│  ⭐ Points: 1,250                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Challenge Page

```
┌─────────────────────────────────────────────────────────────┐
│  🎸 CHALLENGE: "Eruption Solo"                              │
│  Created by: Eddie_Fan • 47 responses • Voting Open         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ORIGINAL                                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  [VIDEO - Original Challenge Short]                  │  │
│  │                                                      │  │
│  │  Posted by Eddie_Fan • 2.3k views                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  TOP RESPONSES                                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │ VIDEO   │ │ VIDEO   │ │ VIDEO   │ │ VIDEO   │          │
│  │         │ │         │ │         │ │         │          │
│  │ 🏆 156  │ │ 134     │ │ 98      │ │ 87      │          │
│  │ votes   │ │ votes   │ │ votes   │ │ votes   │          │
│  │ [Vote]  │ │ [Vote]  │ │ [Vote]  │ │ [Vote]  │          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
│                                                             │
│  [Submit Your Response]                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Merch Store (Band Page Section)

```
┌─────────────────────────────────────────────────────────────┐
│  🛍️ MERCH                                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ [T-Shirt]   │ │ [Hoodie]    │ │ [Poster]    │           │
│  │             │ │             │ │             │           │
│  │ Band Logo   │ │ Tour 2025   │ │ Album Art   │           │
│  │ Tee         │ │ Hoodie      │ │ Print       │           │
│  │             │ │             │ │             │           │
│  │ $25         │ │ $55         │ │ $15         │           │
│  │ [View]      │ │ [View]      │ │ [View]      │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
│  [Visit Full Store →]                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# Part 6: Fan Social Features

Fans need to connect with each other, not just consume content. This creates stickiness and viral sharing.

## 6.1 Activity Feed

A personalized feed showing activity from followed artists AND friends.

### Feed Content Types

- Artist posted a new short
- Artist won MAINSTAGE
- Friend liked/commented on a short
- Friend started following an artist
- Friend attended a gig
- Challenge you voted on has a winner
- Artist you follow has an upcoming gig

### Database

#### `feed_items`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Who sees this item |
| actor_type | string | `User`, `Musician`, `Band` |
| actor_id | bigint | Who did the action |
| action | string | `posted_short`, `liked`, `followed`, `attended_gig`, etc. |
| subject_type | string | What the action was on |
| subject_id | bigint | |
| created_at | datetime | |

### Feed Generation

```ruby
class FeedService
  def generate_feed(user)
    items = []

    # From followed artists
    user.followed_musicians.each do |musician|
      items += musician.recent_activity
    end

    # From friends
    user.friends.each do |friend|
      items += friend.public_activity
    end

    items.sort_by(&:created_at).reverse.take(50)
  end
end
```

### Feed View

```
┌─────────────────────────────────────────────────────────────┐
│  🏠 YOUR FEED                                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🎵 Jane Doe posted a new short                      │   │
│  │    "Acoustic Cover - Wonderwall"                    │   │
│  │    [Video Thumbnail]                                │   │
│  │    ❤️ 45  💬 12  •  2 hours ago                     │   │
│  │    [Like] [Comment] [Share]                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 👤 Your friend Mike liked a short                   │   │
│  │    "Epic Drum Solo" by DrummerBoi                   │   │
│  │    [Video Thumbnail]                                │   │
│  │    3 hours ago                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🏆 The Vibes won MAINSTAGE Headliner!               │   │
│  │    You follow this band                             │   │
│  │    [View MAINSTAGE]                                 │   │
│  │    1 day ago                                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6.2 Fan-to-Fan Friendships

Let fans connect with each other.

### Database

#### `friendships`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| requester_id | bigint | User who sent request |
| addressee_id | bigint | User who received request |
| status | string | `pending`, `accepted`, `declined`, `blocked` |
| created_at | datetime | |

### Friend Discovery

Ways to find friends:
- "Fans who also follow [Artist]"
- "Fans near you"
- "Fans who attended the same gig"
- Import contacts (email, phone)
- Search by username

### Friend Suggestions

```ruby
class FriendSuggestionService
  def suggestions_for(user)
    # Fans with similar taste (follow same artists)
    similar_taste = User.joins(:follows)
                        .where(follows: { followable_id: user.followed_ids })
                        .where.not(id: user.id)
                        .where.not(id: user.friend_ids)
                        .group(:id)
                        .order('COUNT(*) DESC')
                        .limit(10)

    # Fans nearby
    nearby = User.where(location: user.location)
                 .where.not(id: user.id)
                 .limit(10)

    # Fans at same gigs
    gig_buddies = User.joins(:gig_checkins)
                      .where(gig_checkins: { gig_id: user.attended_gig_ids })
                      .where.not(id: user.id)
                      .limit(10)

    (similar_taste + nearby + gig_buddies).uniq
  end
end
```

---

## 6.3 Fan Groups / Communities

Topic-based groups for fans to discuss.

### Group Types

- **Artist Fan Clubs**: Official or unofficial groups for specific artists
- **Genre Communities**: "Jazz Lovers", "Metal Heads", "Indie Folk Fans"
- **Local Scenes**: "LA Music Scene", "Austin Live Music"
- **Interest Groups**: "Guitar Gear Talk", "Home Recording Tips"

### Database

#### `groups`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| name | string | |
| description | text | |
| group_type | string | `fan_club`, `genre`, `local`, `interest` |
| privacy | string | `public`, `private`, `invite_only` |
| creator_id | bigint | |
| artist_id | bigint | If fan club, linked artist (nullable) |
| member_count | integer | Counter cache |
| banner | attachment | |
| created_at | datetime | |

#### `group_memberships`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| group_id | bigint | |
| user_id | bigint | |
| role | string | `member`, `moderator`, `admin` |
| joined_at | datetime | |

#### `group_posts`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| group_id | bigint | |
| author_id | bigint | |
| body | text | |
| media | attachments | Optional images/videos |
| likes_count | integer | |
| comments_count | integer | |
| pinned | boolean | |
| created_at | datetime | |

#### `group_post_comments`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| group_post_id | bigint | |
| author_id | bigint | |
| body | text | |
| created_at | datetime | |

### Group View

```
┌─────────────────────────────────────────────────────────────┐
│  🎸 LA Indie Scene                                          │
│  2,341 members • Public Group                               │
│  [Join Group]                                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [About] [Discussion] [Events] [Members]                    │
│                                                             │
│  📌 PINNED: "Welcome! Read the rules before posting"        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [Avatar] Sarah M. • 2 hours ago                     │   │
│  │                                                      │   │
│  │ Anyone going to the Echo Park show this Saturday?   │   │
│  │ Looking for people to meet up with!                 │   │
│  │                                                      │   │
│  │ ❤️ 23  💬 8 replies                                 │   │
│  │ [Like] [Reply] [Share]                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [Avatar] Mike T. • 5 hours ago                      │   │
│  │                                                      │   │
│  │ Just discovered this band on Kokai - they're       │   │
│  │ playing at The Satellite next week 🔥               │   │
│  │ [Embedded Artist Card]                              │   │
│  │                                                      │   │
│  │ ❤️ 45  💬 12 replies                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [Write a post...]                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6.4 Sharing & Reposts

Let fans share content to their profile and feed.

### Share Types

- **Repost**: Share a short to your followers with optional comment
- **Share to Group**: Post a short to a group you're in
- **External Share**: Share to Twitter, Instagram, etc. with tracking link

### Database

#### `reposts`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Who reposted |
| repostable_type | string | `MusicianShort`, `GroupPost` |
| repostable_id | bigint | |
| comment | text | Optional caption |
| created_at | datetime | |

### Share UI

When clicking share on a short:
```
┌─────────────────────────────────────┐
│  Share this short                   │
├─────────────────────────────────────┤
│                                     │
│  [🔄 Repost to your feed]           │
│                                     │
│  [👥 Share to a group...]           │
│     > LA Indie Scene                │
│     > Jazz Lovers                   │
│                                     │
│  [💬 Send to a friend...]           │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Share externally:                  │
│  [Twitter] [Facebook] [Copy Link]   │
│                                     │
└─────────────────────────────────────┘
```

---

## 6.5 Fan Messaging (DMs)

Direct messaging between fans.

### Features

- One-on-one messaging (already exists for musicians)
- Group chats (up to 20 people)
- Share shorts/profiles in messages
- Message requests from non-friends

### Database Updates

Extend existing `direct_messages` or create:

#### `conversations`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| conversation_type | string | `direct`, `group` |
| name | string | For group chats |
| created_at | datetime | |

#### `conversation_participants`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| conversation_id | bigint | |
| user_id | bigint | |
| role | string | `member`, `admin` |
| last_read_at | datetime | |
| muted | boolean | |

#### `messages` (update existing)
| Column | Type | Description |
|--------|------|-------------|
| conversation_id | bigint | |
| shareable_type | string | Optional embedded content |
| shareable_id | bigint | |

---

## 6.6 Reactions & Expressions

More ways to react beyond likes.

### Reaction Types

- ❤️ Love
- 🔥 Fire
- 👏 Clap
- 🎸 Rock on
- 😮 Wow
- 😢 Sad

### Database

#### `reactions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| reactable_type | string | `MusicianShort`, `GroupPost`, `Comment` |
| reactable_id | bigint | |
| reaction_type | string | `love`, `fire`, `clap`, etc. |
| created_at | datetime | |

Replace simple likes with reactions for richer engagement.

---

## 6.7 Fan Events & Meetups

Fans organize to meet at gigs or create their own events.

### Database

#### `fan_events`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| creator_id | bigint | |
| gig_id | bigint | If tied to an existing gig (nullable) |
| group_id | bigint | If group event (nullable) |
| title | string | |
| description | text | |
| location | string | |
| event_date | datetime | |
| max_attendees | integer | |
| attendee_count | integer | Counter cache |
| created_at | datetime | |

#### `fan_event_attendees`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| fan_event_id | bigint | |
| user_id | bigint | |
| status | string | `going`, `interested`, `not_going` |

### Event Types

- **Gig Meetups**: "Meeting at The Roxy at 7pm for the show"
- **Listening Parties**: "Album release party - streaming together"
- **Fan Gatherings**: "Monthly jazz fans brunch"

---

## 6.8 Notifications (Social)

Keep fans engaged with relevant notifications.

### Notification Types

| Event | Notification |
|-------|--------------|
| Friend request | "Sarah wants to be your friend" |
| Friend accepted | "Mike accepted your friend request" |
| Someone reposted your repost | "Jane reposted your share" |
| Tagged in group post | "You were mentioned in LA Indie Scene" |
| Group post in group you're in | "New post in Jazz Lovers" |
| Event reminder | "Gig meetup tomorrow at 7pm" |
| Friend attending same gig | "3 friends are going to The Echo show" |

### Notification Preferences

Let users control what they receive:
- All notifications
- Friends only
- Artists only
- Mute specific groups
- Daily digest vs. real-time

---

## 6.9 Fan Profiles (Enhanced)

Make fan profiles more interesting and social.

### Profile Sections

```
┌─────────────────────────────────────────────────────────────┐
│  [Banner Image]                                             │
│                                                             │
│  [Avatar] JaneFan                                           │
│           Music enthusiast • Los Angeles                    │
│           "Living for live music 🎵"                        │
│           Joined Nov 2024                                   │
│                                                             │
│  [Add Friend] [Message]                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Activity] [Following] [Friends] [Groups] [Gigs]          │
│                                                             │
│  📊 Stats                                                   │
│  Following: 47 artists  •  Friends: 123  •  Gigs: 12       │
│                                                             │
│  🏆 Badges                                                  │
│  [Super Fan] [Gig Goer] [Early Adopter] [Trendsetter]      │
│                                                             │
│  🎵 Top Artists This Month                                  │
│  1. Jane Doe  2. The Vibes  3. DrummerBoi                  │
│                                                             │
│  📝 Recent Activity                                         │
│  • Liked "Epic Solo" by DrummerBoi                         │
│  • Attended The Echo show                                   │
│  • Joined group "LA Indie Scene"                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Privacy Controls

- Profile visibility: Public / Friends only / Private
- Activity visibility: Show all / Hide likes / Hide follows
- Friend list visibility: Public / Friends only / Hidden

---

# Part 7: Industry / B2B Features

Making Kokai valuable to record labels, booking agents, promoters, and investors.

## 7.1 Industry Account Types

### Record Labels / A&R
**Goal:** Discover unsigned talent early, see proof of engagement

### Booking Agents / Promoters
**Goal:** Find acts for venues/festivals, prove they can draw crowds

### Investors / Analysts
**Goal:** Market trends, emerging genres, platform growth

---

## 7.2 Database Schema

#### `industry_accounts`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| company_name | string | |
| company_type | string | `label`, `agency`, `promoter`, `investor`, `other` |
| website | string | |
| verified | boolean | Manually verified by Kokai |
| tier | string | `free`, `pro`, `enterprise` |
| subscription_expires_at | datetime | |
| created_at | datetime | |

#### `artist_watchlists`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| industry_account_id | bigint | |
| name | string | e.g., "Festival 2026 Potentials" |
| created_at | datetime | |

#### `artist_watchlist_items`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| artist_watchlist_id | bigint | |
| watchable_type | string | `Musician` or `Band` |
| watchable_id | bigint | |
| notes | text | Private notes |
| created_at | datetime | |

#### `industry_alerts`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| industry_account_id | bigint | |
| alert_type | string | `follower_milestone`, `mainstage_winner`, `viral_short`, `new_in_genre` |
| threshold | integer | e.g., 1000 for follower milestone |
| genre_filter | string | Optional |
| location_filter | string | Optional |
| active | boolean | |
| created_at | datetime | |

#### `booking_requests`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| industry_account_id | bigint | Sender |
| recipient_type | string | `Musician` or `Band` |
| recipient_id | bigint | |
| gig_date | date | |
| venue_name | string | |
| location | string | |
| offer_details | text | |
| budget_range | string | |
| status | string | `pending`, `accepted`, `declined`, `expired` |
| created_at | datetime | |

#### `industry_profile_views`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| industry_account_id | bigint | |
| viewable_type | string | `Musician` or `Band` |
| viewable_id | bigint | |
| viewed_at | datetime | |

---

## 7.3 Subscription Tiers

### Free Tier
- Browse public profiles
- Basic search (genre, location)
- 20 profile views per month
- No contact features

### Pro Tier ($75/month)
- Advanced search & filters
- Unlimited profile views
- Save artists to watchlists
- Contact artists directly
- Basic analytics on saved artists
- Export basic reports

### Enterprise Tier ($500+/month)
- Everything in Pro
- A&R alerts & notifications
- Full engagement history
- Fan geography data
- API access
- Custom reports
- Dedicated account manager
- Priority verification

---

## 7.4 Talent Discovery Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  🔍 TALENT DISCOVERY                        [Pro Account]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Filters                                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Genre: [Rock ▼]      Location: [California ▼]       │   │
│  │ Followers: [500+]    Status: [Unsigned only ☑]      │   │
│  │ Growth: [Rising ▼]   MAINSTAGE: [Winners only ☐]    │   │
│  │                                                      │   │
│  │ [Search]  [Save Search]  [Set Alert]                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  47 results • Sorted by: Engagement Score ▼                │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [Av] Jane Doe                              Score: 847│   │
│  │      Guitar • LA • Rock, Indie                      │   │
│  │                                                      │   │
│  │      Followers: 1,247 (↑23%)  Engagement: High      │   │
│  │      🏆 MAINSTAGE Opening Act (Nov 24)              │   │
│  │                                                      │   │
│  │      [View] [Add to Watchlist ▼] [Contact]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [Av] The Vibes (Band)                    Score: 1,203│   │
│  │      4 members • SF • Indie Pop                     │   │
│  │                                                      │   │
│  │      Followers: 2,891 (↑31%)  Engagement: Very High │   │
│  │      🏆 MAINSTAGE Headliner (Nov 17)                │   │
│  │                                                      │   │
│  │      [View] [Add to Watchlist ▼] [Contact]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7.5 Artist Deep Analytics

```
┌─────────────────────────────────────────────────────────────┐
│  📊 ARTIST ANALYTICS: Jane Doe                [Export PDF]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Overview                                                   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Followers    │ │ Monthly      │ │ Engagement   │        │
│  │    1,247     │ │ Growth       │ │ Score        │        │
│  │              │ │    +23%      │ │    847       │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│                                                             │
│  Growth Trajectory (6 months)                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         ╱                                           │   │
│  │       ╱                                             │   │
│  │     ╱                                               │   │
│  │   ╱                                                 │   │
│  │ ╱                                                   │   │
│  │Jun   Jul   Aug   Sep   Oct   Nov                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Fan Geography                   Top Engagement Sources     │
│  ┌────────────────────┐         ┌────────────────────┐     │
│  │ 1. Los Angeles 34% │         │ Shorts Likes: 42%  │     │
│  │ 2. San Diego   12% │         │ Comments: 28%      │     │
│  │ 3. Phoenix      8% │         │ Follows: 18%       │     │
│  │ 4. Las Vegas    6% │         │ Profile Views: 12% │     │
│  │ 5. Other       40% │         └────────────────────┘     │
│  └────────────────────┘                                    │
│                                                             │
│  MAINSTAGE History                                          │
│  • Nov 24: Opening Act (Rank #4, Score: 276)               │
│  • Nov 10: Ranked #12                                       │
│                                                             │
│  [Add to Watchlist]  [Send Booking Request]  [Export]       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7.6 A&R Alerts

```
┌─────────────────────────────────────────────────────────────┐
│  🔔 A&R ALERTS                              [+ New Alert]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Recent Alerts (3 new)                                      │
│                                                             │
│  🔴 NEW • 2 hours ago                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📈 Follower Milestone: DrummerBoi hit 1,000         │   │
│  │    Genre: Rock • Location: LA                       │   │
│  │    [View Profile]                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  🔴 NEW • 5 hours ago                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🏆 MAINSTAGE Winner: The Satellites                 │   │
│  │    Won Headliner this week                          │   │
│  │    [View Profile]                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Your Alert Rules                                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⚡ Follower Milestone (1,000+)                      │   │
│  │    Genre: Rock, Indie | Location: California        │   │
│  │    [Edit] [Pause] [Delete]                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🏆 MAINSTAGE Winners (All)                          │   │
│  │    Genre: Any | Location: Any                       │   │
│  │    [Edit] [Pause] [Delete]                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7.7 Booking Requests

```
┌─────────────────────────────────────────────────────────────┐
│  📨 SEND BOOKING REQUEST                                    │
│  To: Jane Doe                                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Event Details                                              │
│                                                             │
│  Venue: [The Roxy Theatre________________]                  │
│                                                             │
│  Location: [Los Angeles, CA______________]                  │
│                                                             │
│  Date: [Dec 15, 2025]    Time: [8:00 PM]                   │
│                                                             │
│  Event Type: [○ Headline  ● Support  ○ Festival]           │
│                                                             │
│  Budget Range: [$500 - $1,000 ▼]                           │
│                                                             │
│  Details:                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ We're looking for an opening act for our indie     │   │
│  │ night series. Your sound would be perfect for      │   │
│  │ our audience. 45-minute set, backline provided.    │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [Send Request]                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7.8 Artist Benefits

What artists get from industry features:

### Visibility Badge
- "Discoverable" badge on profile
- Opt-in to appear in industry searches

### Industry Interest Indicators
- "Viewed by 5 industry professionals this week" (on dashboard, not public)
- Notification when label/agent views profile

### Booking Inbox
- Professional opportunities come to them
- Accept/decline with response templates
- Rating system for industry accounts

### Data for Negotiation
- Export their own analytics
- Prove their worth with hard numbers
- "My engagement score is top 5% on Kokai"

---

## 7.9 Revenue Model

| Source | Pricing |
|--------|---------|
| Pro Subscriptions | $75/month |
| Enterprise Subscriptions | $500+/month (custom) |
| Booking Transaction Fee | 5% of confirmed bookings |
| Featured Placement | Artists pay $50-200 to be featured in discovery |
| API Access | $0.01 per request (enterprise) |
| Quarterly Trend Reports | $500 per report |

---

## 7.10 Trust & Safety

### Industry Verification
- Manual review of company email domain
- LinkedIn verification
- Business registration check
- Verified badge visible to artists

### Artist Protection
- Control detailed analytics visibility
- Block specific companies
- Report bad actors
- See full view history

### Platform Moderation
- Review flagged industry accounts
- Monitor booking request quality
- Ban accounts with poor ratings

---

# Part 8: Updated Implementation Phases

## Phase 1: Foundation (Week 1-2)
1. Follow system (polymorphic)
2. Profile view tracking
3. Profile saves/bookmarks
4. Basic owner dashboard

## Phase 2: Fan Social - Core (Week 3-4)
5. Fan-to-fan friendships
6. Activity feed (basic)
7. Reposts/sharing
8. Enhanced fan profiles

## Phase 3: Music & Content (Week 5-6)
9. Spotify/music embeds
10. Endorsements
11. Shoutouts
12. Reactions (beyond likes)

## Phase 4: Fan Social - Advanced (Week 7-8)
13. Groups/communities
14. Group posts & discussions
15. Fan messaging (extend DMs)
16. Fan events/meetups

## Phase 5: Challenges & Viral (Week 9-10)
17. Challenge/duet system
18. Challenge voting
19. Share tracking
20. Referral system

## Phase 6: MAINSTAGE (Week 11-12)
21. MAINSTAGE scoring
22. MAINSTAGE page & hall of fame
23. Winner notifications
24. Profile badges

## Phase 7: Fan Monetization (Week 13-14)
25. Fan points system
26. Badges & rewards
27. Merch links
28. Embeddable widgets

## Phase 8: Industry B2B (Week 15-18)
29. Industry account signup & verification
30. Talent discovery search
31. Artist watchlists
32. A&R alerts
33. Booking requests
34. Subscription billing
35. Analytics exports

---

# Part 9: Success Metrics

## User Growth
- Monthly Active Users (MAU)
- Fan:Musician ratio (target: 10:1)
- New signups per week
- User retention (D1, D7, D30)

## Engagement
- Follows per user
- Likes/comments per short
- Group posts per week
- Messages sent per user
- Time on site

## Social
- Friends per fan
- Group memberships per fan
- Reposts per short
- Event attendance rate

## Monetization
- Industry account conversions (free → pro)
- Booking requests sent/accepted
- Merch clicks/purchases
- Fan points redeemed

## Artist Success
- Artists discovered by industry
- Booking requests received
- MAINSTAGE winners who get signed/booked

---

# Part 10: Real-Life Engagement & Verified Check-ins

## 10.1 The Problem

Online engagement is only half the picture. A musician might have viral shorts but empty shows. Conversely, some artists pack venues but have minimal online presence. We need to bridge the gap between digital engagement and real-world attendance.

**Goals:**
- Verify that fans actually attend shows (not just click "interested")
- Reward fans for real-world support
- Give artists proof of draw for booking negotiations
- Create a flywheel: online engagement → show attendance → more online engagement

---

## 10.2 Verified Check-in System

### How It Works

1. **Fan arrives at venue** for a gig
2. **Opens Kokai app** and taps "Check In"
3. **Location verified** via GPS (must be within ~500m of venue)
4. **Time verified** (must be during or shortly before the gig)
5. **Check-in confirmed** - fan earns points and badge
6. **Artist gets credit** for verified attendance

### Verification Methods

| Method | Accuracy | Effort | Notes |
|--------|----------|--------|-------|
| GPS Location | Medium | Low | Can be spoofed, but good enough for most cases |
| QR Code at Venue | High | Medium | Venue displays code, fan scans |
| NFC Tap | High | Medium | Tap phone at venue terminal |
| Photo + Location | High | Low | Photo with geotag, manual review if flagged |
| Ticket Integration | Very High | High | Connect to Eventbrite/Ticketmaster |

**Recommendation:** Start with GPS + Photo, add QR codes for venues that want them.

---

## 10.3 Database Schema

#### `event_checkins`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Fan checking in |
| gig_id | bigint | The gig (nullable if ad-hoc) |
| venue_id | bigint | Venue (for non-gig check-ins) |
| musician_id | bigint | If checking in for specific artist |
| band_id | bigint | If checking in for specific band |
| verification_method | string | `gps`, `qr_code`, `nfc`, `photo`, `ticket` |
| latitude | decimal | User's location at check-in |
| longitude | decimal | |
| checked_in_at | datetime | |
| verified | boolean | Default true, flagged if suspicious |
| photo | attachment | Optional photo from the show |
| notes | text | Fan's comment about the show |
| points_awarded | integer | Points earned |
| created_at | datetime | |

**Indexes:**
- `[user_id, gig_id]` unique (one check-in per gig per user)
- `[gig_id, checked_in_at]` for counting attendance
- `[musician_id, checked_in_at]` for artist stats

#### `venue_checkin_codes`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| venue_id | bigint | |
| gig_id | bigint | Optional - code for specific gig |
| code | string | Unique QR/NFC code |
| active | boolean | |
| expires_at | datetime | |
| created_at | datetime | |

#### `checkin_rewards`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| event_checkin_id | bigint | |
| reward_type | string | `points`, `badge`, `discount`, `exclusive_content` |
| reward_value | string | Points amount or reward identifier |
| claimed | boolean | |
| claimed_at | datetime | |

---

## 10.4 Check-in Flow

### Basic GPS Check-in

```ruby
class EventCheckinsController < ApplicationController
  def create
    @gig = Gig.find(params[:gig_id])

    # Verify location
    unless within_venue_radius?(params[:latitude], params[:longitude], @gig.venue)
      return render json: { error: "You don't appear to be at the venue" }, status: :unprocessable_entity
    end

    # Verify time (allow 2 hours before start, up to 4 hours after)
    unless valid_checkin_window?(@gig)
      return render json: { error: "Check-in window has passed" }, status: :unprocessable_entity
    end

    @checkin = current_user.event_checkins.create!(
      gig: @gig,
      venue: @gig.venue,
      musician: @gig.band&.musicians&.first, # or specific headliner
      band: @gig.band,
      verification_method: 'gps',
      latitude: params[:latitude],
      longitude: params[:longitude],
      points_awarded: calculate_points(@gig)
    )

    # Award points
    current_user.fan_points.increment!(:points, @checkin.points_awarded)
    FanPointTransaction.create!(user: current_user, amount: @checkin.points_awarded, action: 'gig_checkin')

    # Award badges if applicable
    award_checkin_badges(current_user, @gig)

    # Notify artist
    notify_artist_of_checkin(@checkin)
  end

  private

  def within_venue_radius?(lat, lng, venue, radius_meters: 500)
    # Haversine formula for distance
    distance = Geocoder::Calculations.distance_between(
      [lat, lng],
      [venue.latitude, venue.longitude],
      units: :m
    )
    distance <= radius_meters
  end

  def valid_checkin_window?(gig)
    window_start = gig.start_time - 2.hours
    window_end = gig.start_time + 4.hours
    Time.current.between?(window_start, window_end)
  end

  def calculate_points(gig)
    base_points = 20

    # Bonus for first-time seeing this artist
    first_time_bonus = first_time_seeing?(current_user, gig.band) ? 10 : 0

    # Bonus for checking in early (not last minute)
    early_bird_bonus = Time.current < gig.start_time ? 5 : 0

    base_points + first_time_bonus + early_bird_bonus
  end
end
```

### QR Code Check-in

```ruby
class QrCheckinsController < ApplicationController
  def scan
    code = VenueCheckinCode.active.find_by(code: params[:code])

    unless code
      return render json: { error: "Invalid or expired code" }, status: :not_found
    end

    gig = code.gig || code.venue.current_gig

    @checkin = current_user.event_checkins.create!(
      gig: gig,
      venue: code.venue,
      verification_method: 'qr_code',
      points_awarded: 25 # Bonus for QR verification
    )

    # Same rewards flow as above
  end
end
```

---

## 10.5 Fan Rewards for Check-ins

### Points System (Enhanced)

| Action | Points | Notes |
|--------|--------|-------|
| Basic check-in (GPS) | 20 | Standard show attendance |
| QR/NFC verified check-in | 25 | Higher trust verification |
| First time seeing artist | +10 | Discovery bonus |
| Early bird (before show starts) | +5 | Encourages arriving early |
| Photo with check-in | +5 | User-generated content |
| Check-in streak (3+ shows/month) | +15 | Loyalty bonus |
| Bringing a friend (both check in) | +10 each | Referral to real life |

### Badges

| Badge | Requirement | Description |
|-------|-------------|-------------|
| 🎫 Gig Goer | 5 check-ins | Regular show attendee |
| 🎪 Festival Fan | 10 check-ins | Dedicated live music fan |
| 🌟 Super Supporter | 25 check-ins | Serious scene supporter |
| 🏆 Scene Legend | 50 check-ins | Legendary live music presence |
| 🔥 Streak Master | 4-week streak | Consistent attendance |
| 🎸 Artist Superfan | 5 shows same artist | Dedicated follower |
| 🌍 Venue Explorer | 10 different venues | Variety seeker |
| 🌅 Early Bird | 10 early check-ins | Always there early |

### Exclusive Rewards

```ruby
# Fan can redeem points for:
REWARDS = {
  merch_discount_10: { points: 100, description: "10% off merch at any artist" },
  merch_discount_25: { points: 200, description: "25% off merch at any artist" },
  meet_greet_raffle: { points: 150, description: "Entry into meet & greet lottery" },
  exclusive_content: { points: 50, description: "Unlock behind-the-scenes content" },
  front_row_priority: { points: 300, description: "Priority entry at next show" },
  signed_poster: { points: 500, description: "Signed poster from artist (if available)" }
}
```

---

## 10.6 Artist Benefits

### Dashboard Stats

```
┌─────────────────────────────────────────────────────────────┐
│  🎫 LIVE PERFORMANCE STATS                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Total Verified Attendees: 1,247                            │
│                                                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Last Show    │ │ Avg per Show │ │ Return Rate  │        │
│  │     156      │ │     89       │ │    34%       │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│                                                             │
│  Recent Shows                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Nov 23 - The Echo       | 156 verified | 78 new fans│   │
│  │ Nov 15 - The Satellite  | 98 verified  | 45 new fans│   │
│  │ Nov 8 - The Troubadour  | 134 verified | 52 new fans│   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Fan Geography (from check-ins)                             │
│  Los Angeles: 67%  |  San Diego: 12%  |  Other: 21%        │
│                                                             │
│  [Download Proof of Draw Report]                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Proof of Draw Document

Artists can generate a PDF report showing:
- Total verified attendees across shows
- Average attendance per show
- Fan geography distribution
- Return visitor rate
- Growth trend over time

**This is GOLD for booking negotiations.** Instead of saying "we draw about 100 people," artists can say "We have 1,247 verified unique attendees across 14 shows, with a 34% return rate and 89 average per show."

### MAINSTAGE Integration

Real-life engagement feeds into MAINSTAGE score:

| Metric | Points per Instance |
|--------|---------------------|
| Verified fan check-in | 5 points to artist |
| New fan's first check-in | 8 points (discovery bonus) |
| Fan photo posted | 3 points |
| Return visitor check-in | 7 points (loyalty bonus) |

---

## 10.7 Venue Benefits

### Venue Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  🏢 VENUE: The Echo - Dashboard                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Tonight's Show                                             │
│  Band: The Vibes  |  Doors: 8pm  |  QR Code: [ACTIVE]       │
│                                                             │
│  Real-time Check-ins: 47 (and counting...)                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [QR Code for Tonight]                               │   │
│  │                                                      │   │
│  │ Display this at the entrance for                    │   │
│  │ fans to scan and check in                           │   │
│  │                                                      │   │
│  │ [Download] [Print] [Send to Door Staff]             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Historical Data                                            │
│  • Total check-ins this month: 1,892                        │
│  • Average per show: 126                                    │
│  • Top performing night: Saturday (avg 167)                 │
│                                                             │
│  [Generate Monthly Report]                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Benefits for Venues
- Real attendance data (not just ticket sales - some shows are free)
- Fan demographics and preferences
- Proof of venue popularity for sponsors
- Understand which artists draw best

---

## 10.8 Anti-Fraud Measures

### Detection Methods

1. **Velocity Check**: Flag if same user checks in to multiple distant venues quickly
2. **Photo Analysis**: EXIF data verification, duplicate image detection
3. **Device Fingerprinting**: Track if same device is used for multiple accounts
4. **Time Pattern Analysis**: Flag users who always check in at exactly the same time
5. **Social Verification**: Option for friends to "verify" each other's attendance

### Suspicious Activity Flags

```ruby
class CheckinFraudDetector
  def analyze(checkin)
    flags = []

    # Check for GPS spoofing patterns
    if suspicious_location_pattern?(checkin.user)
      flags << :location_anomaly
    end

    # Check for impossible travel
    if impossible_travel?(checkin)
      flags << :impossible_travel
    end

    # Check for duplicate photos
    if duplicate_photo?(checkin.photo)
      flags << :duplicate_photo
    end

    # Flag but don't auto-reject
    if flags.any?
      checkin.update(flagged: true, flag_reasons: flags)
      AdminNotification.create(subject: checkin, type: 'suspicious_checkin')
    end
  end

  def impossible_travel?(checkin)
    last_checkin = checkin.user.event_checkins.where.not(id: checkin.id).order(created_at: :desc).first
    return false unless last_checkin

    time_diff = checkin.created_at - last_checkin.created_at
    distance = Geocoder::Calculations.distance_between(
      [checkin.latitude, checkin.longitude],
      [last_checkin.latitude, last_checkin.longitude],
      units: :km
    )

    # If distance/time suggests >200 km/h travel, flag it
    speed_kmh = (distance / (time_diff / 1.hour))
    speed_kmh > 200
  end
end
```

### Penalty System

- **First offense**: Warning, points not awarded
- **Second offense**: Points revoked, 30-day check-in suspension
- **Third offense**: Permanent ban from check-in rewards
- **Severe fraud**: Account suspension pending review

---

## 10.9 Integration with Existing Features

### Feed Integration

When a fan checks in:
```
┌─────────────────────────────────────────────────────────────┐
│ 🎫 Sarah just checked in at The Echo                       │
│    Seeing: The Vibes                                        │
│    [Photo from the show]                                    │
│    "Amazing energy tonight! 🔥"                             │
│                                                             │
│    ❤️ 23  💬 5  •  2 hours ago                              │
│    [Like] [Comment] [I'm here too!]                         │
└─────────────────────────────────────────────────────────────┘
```

### Friend Meetup Feature

When friends are at the same show:
```
┌─────────────────────────────────────────────────────────────┐
│ 🎉 3 of your friends are at The Echo tonight!               │
│                                                             │
│ [Avatar] Mike  [Avatar] Sarah  [Avatar] John                │
│                                                             │
│ [Message Group] [Find Them]                                 │
└─────────────────────────────────────────────────────────────┘
```

### Post-Show Engagement

After a show, fans can:
- Rate the performance (1-5 stars, private to artist)
- Leave a review (public or private)
- Share their photo to the artist's page
- Tag the short they want to see next

---

## 10.10 Implementation Phases

### Phase 1: Basic Check-ins (Week 1-2)
- GPS-based check-in
- Basic points system
- Simple badges
- Artist notification of check-ins

### Phase 2: Enhanced Verification (Week 3-4)
- Photo upload with check-in
- QR code generation for venues
- Anti-fraud detection (basic)
- Venue dashboard

### Phase 3: Rewards & Integration (Week 5-6)
- Full badge system
- Points redemption
- Feed integration
- Friend meetup features

### Phase 4: Artist Analytics (Week 7-8)
- Proof of draw reports
- MAINSTAGE integration
- Geographic fan data
- Return visitor tracking

### Phase 5: Advanced Features (Week 9-10)
- NFC tap check-ins
- Ticket platform integration
- Premium venue features
- Enterprise analytics

---

## 10.11 Success Metrics

| Metric | Target |
|--------|--------|
| Check-in adoption rate | 30% of users with gig nearby |
| Verified check-ins per gig | 50+ average |
| Points redemption rate | 40% of earned points |
| Fraud rate | <2% flagged, <0.5% confirmed |
| Artist satisfaction | 4.5/5 on "useful for booking" |
| Return attendance rate | 25%+ fans return to same artist |

---

## 10.12 Future Possibilities

### Ticket Integration
- Partner with Eventbrite, Ticketmaster, DICE
- Auto-check-in when ticket is scanned
- Import past attendance history

### Wearables
- Apple Watch / WearOS app for quick check-ins
- NFC wristbands at festivals

### AR Features
- "Fan cam" - AR overlay showing other Kokai users nearby
- Shared AR experiences at shows

### Gamification
- "Collect all venues" city-based achievements
- Artist scavenger hunts
- Fan-vs-fan attendance competitions

### Monetization
- Premium check-in features (detailed stats)
- Venue subscriptions for advanced analytics
- "VIP Fan" status with real-world perks

---

# Part 11: Extended Real-World Engagement Features

Beyond gig check-ins, there are many more ways to bridge physical and digital engagement.

---

## 11.1 Merch Verification System

Physical merchandise becomes a verified connection between fan and artist.

### How It Works

1. Artist adds unique QR codes to merch (printed on tags, stickers, or packaging)
2. Fan purchases merch at show or online
3. Fan scans QR code to "register" the item
4. Fan unlocks exclusive content and earns points
5. Artist gets verified sales data

### Database Schema

#### `merch_codes`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| band_id | bigint | |
| musician_id | bigint | |
| code | string | Unique scannable code |
| item_type | string | `tshirt`, `hoodie`, `vinyl`, `poster`, `sticker`, etc. |
| item_name | string | e.g., "Tour 2025 Black Tee" |
| batch_id | string | For tracking production runs |
| redeemed | boolean | Default false |
| redeemed_by_id | bigint | User who claimed it |
| redeemed_at | datetime | |
| created_at | datetime | |

#### `merch_registrations`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| merch_code_id | bigint | |
| points_awarded | integer | |
| unlocked_content | jsonb | What they got access to |
| photo | attachment | Optional photo of them with merch |
| created_at | datetime | |

### Rewards for Merch Registration

| Item Type | Points | Bonus |
|-----------|--------|-------|
| Sticker | 10 | - |
| Poster | 20 | - |
| T-shirt | 30 | Unlock exclusive wallpaper |
| Hoodie | 40 | Unlock behind-the-scenes video |
| Vinyl/CD | 50 | Unlock bonus track or demo |
| Limited Edition | 75 | Early access to next release |

### Artist Benefits

- Know exactly how many items sold (not just shipped to retailers)
- See geographic distribution of merch sales
- Connect with superfans who buy multiple items
- "X verified owners" badge on merch store

### Merch Collector Badges

| Badge | Requirement |
|-------|-------------|
| 👕 Merch Supporter | Register 1 item |
| 🛍️ Merch Collector | Register 5 items |
| 💎 Superfan Collector | Register 10+ items from same artist |
| 🌈 Variety Collector | Register items from 10 different artists |

---

## 11.2 Tip Jar / Street Performer Mode

For buskers, open mic performers, and impromptu performances.

### How It Works

1. Musician enables "Tip Jar Mode" in app
2. App generates a QR code with their profile
3. Display QR code while performing (phone stand, printed sign)
4. Passersby scan to tip (Stripe/PayPal integration)
5. Tipper automatically follows artist, earns points
6. Creates verified "discovered in the wild" connection

### Database Schema

#### `tip_jar_sessions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| musician_id | bigint | |
| location_name | string | e.g., "Pike Place Market" |
| latitude | decimal | |
| longitude | decimal | |
| started_at | datetime | |
| ended_at | datetime | |
| total_tips_cents | integer | |
| tip_count | integer | |
| new_followers_count | integer | |

#### `tips`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| tip_jar_session_id | bigint | |
| tipper_id | bigint | User who tipped |
| musician_id | bigint | |
| amount_cents | integer | |
| message | text | Optional note |
| stripe_payment_id | string | |
| created_at | datetime | |

### Fan Rewards

| Action | Points |
|--------|--------|
| Tip any amount | 15 |
| Tip $5+ | 25 |
| First tip to new artist | +10 bonus |
| Tip streak (3 different artists) | +20 bonus |

### Badges

| Badge | Requirement |
|-------|-------------|
| 🎩 Street Supporter | Tip 1 busker |
| 🌟 Talent Scout | Tip 5 different street performers |
| 💰 Generous Patron | Tip $50+ total |
| 🗺️ City Explorer | Tip performers in 3 different cities |

### Artist Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  🎩 TIP JAR STATS                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Total Tips Received: $342.50                               │
│  Unique Tippers: 67                                         │
│  Converted to Followers: 45 (67%)                           │
│                                                             │
│  Best Locations                                             │
│  1. Pike Place Market - $156 (23 tips)                      │
│  2. Santa Monica Pier - $98 (18 tips)                       │
│  3. Union Square - $88 (26 tips)                            │
│                                                             │
│  [Start Tip Jar Session]                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 11.3 Live Setlist Voting

Real-time song voting during performances.

### How It Works

1. Artist starts a "Live Set" mode before performing
2. Fans at the venue (location-verified) can vote on songs
3. Artist sees real-time results on their device
4. Winning song gets played, voters earn points
5. Creates engagement DURING the show, not just before/after

### Database Schema

#### `live_sets`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| band_id | bigint | |
| gig_id | bigint | Optional |
| venue_id | bigint | |
| started_at | datetime | |
| ended_at | datetime | |
| status | string | `active`, `paused`, `ended` |

#### `setlist_polls`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| live_set_id | bigint | |
| question | string | e.g., "What should we play next?" |
| status | string | `open`, `closed` |
| winner_option_id | bigint | |
| opened_at | datetime | |
| closed_at | datetime | |

#### `setlist_poll_options`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| setlist_poll_id | bigint | |
| song_title | string | |
| votes_count | integer | Counter cache |

#### `setlist_poll_votes`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| setlist_poll_option_id | bigint | |
| user_id | bigint | |
| latitude | decimal | For location verification |
| longitude | decimal | |
| created_at | datetime | |

### Fan Experience

```
┌─────────────────────────────────────────────────────────────┐
│  🎤 LIVE: The Vibes @ The Echo                              │
│  "What should we play next?"                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ████████████████████░░░░  "Midnight Drive" (67%)           │
│  ██████████░░░░░░░░░░░░░░  "Summer Haze" (23%)              │
│  ████░░░░░░░░░░░░░░░░░░░░  "City Lights" (10%)              │
│                                                             │
│  47 fans voting • Closes in 0:45                            │
│                                                             │
│  [Vote] You voted for "Midnight Drive" ✓                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Rewards

| Action | Points |
|--------|--------|
| Vote in live poll | 5 |
| Vote for winning song | +3 bonus |
| Vote in 5+ polls same show | +10 bonus |

### Artist Benefits

- Real-time crowd feedback
- Know which songs fans actually want
- Data on song popularity by city/venue
- "Fan favorite" tags on songs

---

## 11.4 Physical Music Verification (Vinyl/CD)

Verify ownership of physical music releases.

### How It Works

1. Artist includes unique code inside vinyl sleeve, CD booklet, or cassette case
2. Fan purchases physical music
3. Fan enters code or scans QR to register
4. Unlocks bonus content (demos, stems, commentary)
5. Creates "vinyl collector" connection

### Database Schema

#### `physical_release_codes`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| band_id | bigint | |
| musician_id | bigint | |
| release_title | string | Album/EP name |
| format | string | `vinyl`, `cd`, `cassette`, `box_set` |
| code | string | Unique code |
| edition | string | `standard`, `limited`, `signed` |
| redeemed | boolean | |
| redeemed_by_id | bigint | |
| redeemed_at | datetime | |

### Unlockable Content

| Format | Unlocks |
|--------|---------|
| CD | Digital download + bonus track |
| Vinyl | High-res audio files + liner notes PDF |
| Cassette | Exclusive B-side + retro filter for profile |
| Limited Edition | All above + video commentary |
| Signed Copy | All above + artist shoutout video |

### Collector Badges

| Badge | Requirement |
|-------|-------------|
| 💿 CD Collector | Register 3 CDs |
| 🎵 Vinyl Head | Register 3 vinyl records |
| 📼 Retro Fan | Register any cassette |
| 📦 Complete Set | Register all formats from one release |
| 🏆 Physical Purist | Register 20+ physical items |

---

## 11.5 Lesson & Workshop Verification

Connect teachers and students through verified instruction.

### How It Works

1. Musician marks themselves as offering lessons
2. Creates a lesson session with unique code
3. Student checks in at start of lesson
4. Both earn points and build connection
5. Student can display "learned from" on profile

### Database Schema

#### `lesson_sessions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| teacher_id | bigint | Musician teaching |
| student_id | bigint | User learning |
| lesson_type | string | `private`, `group`, `workshop`, `masterclass` |
| topic | string | e.g., "Jazz improvisation basics" |
| duration_minutes | integer | |
| location | string | |
| verified | boolean | Both parties confirmed |
| teacher_points | integer | |
| student_points | integer | |
| session_date | datetime | |
| created_at | datetime | |

#### `mentorship_connections`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| teacher_id | bigint | |
| student_id | bigint | |
| total_lessons | integer | Counter |
| skills_taught | string[] | Array of skills |
| public_display | boolean | Show on profiles |
| started_at | datetime | |

### Profile Display

```
┌─────────────────────────────────────────────────────────────┐
│  🎓 LEARNING JOURNEY                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Studied with:                                              │
│  [Avatar] Jane Doe - Jazz Guitar (12 lessons)               │
│  [Avatar] Mike Smith - Music Theory (5 lessons)             │
│                                                             │
│  Skills Learned:                                            │
│  [Jazz Improv] [Chord Voicings] [Sight Reading]            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Teacher Profile

```
┌─────────────────────────────────────────────────────────────┐
│  🎓 TEACHING STATS                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Total Students: 47                                         │
│  Total Lessons Given: 234                                   │
│  Specialties: Jazz Guitar, Music Theory                     │
│                                                             │
│  Recent Students:                                           │
│  [Avatar] [Avatar] [Avatar] [Avatar] +43 more              │
│                                                             │
│  [I Offer Lessons] ← Toggle to show on profile              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Badges

| Badge | Requirement |
|-------|-------------|
| 📚 Student | Complete 5 lessons |
| 🎓 Dedicated Learner | Complete 20 lessons |
| 👨‍🏫 Teacher | Teach 10 lessons |
| 🏫 Master Instructor | Teach 50 lessons |
| 🤝 Mentorship | 10+ lessons with same teacher |

---

## 11.6 Jam Session & Open Mic Verification

Verify collaborative musical experiences.

### How It Works

1. Musician creates a "Jam Session" event
2. Other musicians check in when they join
3. All participants verify each other
4. Creates "played with" connections
5. Builds collaboration network with real-world proof

### Database Schema

#### `jam_sessions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| creator_id | bigint | Musician who started it |
| venue_id | bigint | Optional |
| location_name | string | |
| latitude | decimal | |
| longitude | decimal | |
| session_type | string | `jam`, `open_mic`, `rehearsal`, `recording` |
| started_at | datetime | |
| ended_at | datetime | |
| public | boolean | Visible on feed |

#### `jam_participants`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| jam_session_id | bigint | |
| musician_id | bigint | |
| instrument_played | string | What they played |
| verified_by_count | integer | How many others verified them |
| joined_at | datetime | |

#### `jam_verifications`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| verifier_id | bigint | Musician verifying |
| verified_id | bigint | Musician being verified |
| jam_session_id | bigint | |
| created_at | datetime | |

### Collaboration Network

When two musicians verify each other at a jam:
- Both get "Played with [Name]" on profile
- Connection strength increases with more jams
- Creates a visual collaboration graph

### Profile Display

```
┌─────────────────────────────────────────────────────────────┐
│  🎸 COLLABORATION NETWORK                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Played with 23 musicians                                   │
│                                                             │
│  Frequent Collaborators:                                    │
│  [Avatar] Mike (Drums) - 12 sessions                        │
│  [Avatar] Sarah (Bass) - 8 sessions                         │
│  [Avatar] John (Keys) - 5 sessions                          │
│                                                             │
│  Recent Sessions:                                           │
│  • Jazz Jam @ Blue Note - Nov 28 (4 musicians)              │
│  • Open Mic @ The Local - Nov 21 (verified)                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Badges

| Badge | Requirement |
|-------|-------------|
| 🎵 Jammer | Attend 5 jam sessions |
| 🤝 Collaborator | Play with 10 different musicians |
| 🎪 Session Regular | 20+ jams at same venue |
| 🌐 Network Builder | 50+ verified connections |
| 🎤 Open Mic Hero | 10 open mic appearances |

---

## 11.7 AI-Powered Photo Verification

Use computer vision to verify attendance and purchases.

### How It Works

1. Fan uploads photo from show or with merch
2. AI analyzes for: band logos, stage presence, venue markers, merch items
3. Auto-tags relevant artist/venue
4. Creates verified connection without manual codes

### Use Cases

| Photo Type | AI Detection | Result |
|------------|--------------|--------|
| Concert photo | Stage, band members, venue logo | Verify attendance |
| Selfie with merch | T-shirt logo, design pattern | Verify merch ownership |
| Ticket stub | Event name, date, venue | Verify purchase |
| Meet & greet | Face matching with artist | Verify VIP experience |
| Signed item | Signature pattern matching | Verify authenticity |

### Database Schema

#### `photo_verifications`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| photo | attachment | |
| verification_type | string | `concert`, `merch`, `ticket`, `meet_greet` |
| ai_confidence | decimal | 0.0-1.0 |
| detected_entities | jsonb | What AI found |
| verified | boolean | Manual override if needed |
| linked_band_id | bigint | |
| linked_musician_id | bigint | |
| linked_gig_id | bigint | |
| linked_venue_id | bigint | |
| created_at | datetime | |

### AI Detection Response

```json
{
  "detected_entities": {
    "band_logo": { "name": "The Vibes", "confidence": 0.94 },
    "venue": { "name": "The Echo", "confidence": 0.87 },
    "stage_presence": true,
    "crowd_visible": true,
    "estimated_date": "2025-11-28",
    "merch_items": []
  },
  "suggested_verification": "gig_attendance",
  "overall_confidence": 0.91
}
```

### Privacy Considerations

- No facial recognition of other fans (only artist matching if enabled)
- Photos stored securely, not shared without permission
- AI runs on-device when possible
- User can delete verification data anytime

---

## 11.8 Local Music Business Partnerships

Partner with music-related businesses for check-ins.

### Partner Types

| Business Type | Check-in Benefit |
|---------------|------------------|
| Guitar/Music Shops | "Gear Head" points, store discounts |
| Record Stores | "Vinyl Hunter" points, exclusive releases |
| Music Venues | Early show announcements, priority entry |
| Rehearsal Studios | "Dedicated Musician" badge |
| Music Schools | Student/teacher verification |
| Instrument Repair | "Gear Care" badge |

### Database Schema

#### `partner_locations`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| name | string | |
| business_type | string | |
| address | string | |
| latitude | decimal | |
| longitude | decimal | |
| partner_tier | string | `basic`, `premium`, `exclusive` |
| checkin_points | integer | |
| active | boolean | |

#### `partner_checkins`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| partner_location_id | bigint | |
| verification_method | string | `gps`, `qr_code`, `purchase` |
| points_awarded | integer | |
| purchase_amount_cents | integer | Optional |
| checked_in_at | datetime | |

### Partner Dashboard

Partners get analytics on:
- Check-in traffic from Kokai users
- Demographics of music fans visiting
- Conversion from check-in to purchase
- Comparison to other partner locations

### Badges

| Badge | Requirement |
|-------|-------------|
| 🎸 Gear Head | 5 music shop check-ins |
| 💿 Crate Digger | 10 record store check-ins |
| 🏠 Local Supporter | Check in at 10 different local businesses |
| 🌟 Scene Builder | 50 total partner check-ins |

### Rewards

- Partner-specific discounts (10% off at participating stores)
- Exclusive merch only available through check-ins
- Early access to limited releases at record stores
- Free rehearsal room time at partner studios

---

## 11.9 MAINSTAGE Integration for All Real-World Features

All real-world engagement feeds into MAINSTAGE scoring.

### Points to Artist

| Real-World Action | MAINSTAGE Points |
|-------------------|------------------|
| Verified gig attendance | 5 |
| Merch registration | 8 |
| Tip received | 3 per dollar (capped at 30) |
| Setlist vote received | 2 |
| Physical release registered | 10 |
| Lesson taught | 5 |
| Jam session (verified) | 4 |
| Photo verification | 3 |
| Partner check-in (at artist's show venue) | 2 |

### "Real-World Champion" Category

New MAINSTAGE category for artists with strongest real-world presence:
- Weighs physical engagement higher
- Rewards artists who tour actively
- Recognizes teaching and mentorship
- Highlights local scene builders

### Leaderboard Display

```
┌─────────────────────────────────────────────────────────────┐
│  🏆 MAINSTAGE: Real-World Champions                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 🥇 Jane Doe                                             │
│     📍 12 shows | 👕 89 merch | 🎓 47 students | Score: 1,847│
│                                                             │
│  2. 🥈 The Vibes                                            │
│     📍 18 shows | 👕 234 merch | 🎤 14 jams | Score: 1,623  │
│                                                             │
│  3. 🥉 DrummerBoi                                           │
│     📍 8 shows | 🎩 $450 tips | 🎓 23 students | Score: 1,456│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 11.10 Implementation Priority

### Phase 1: Foundation (Weeks 1-3)
1. Gig check-ins (from Part 10)
2. Merch verification (basic QR codes)
3. Tip jar mode

### Phase 2: Collaboration (Weeks 4-6)
4. Jam session verification
5. Lesson tracking
6. Open mic check-ins

### Phase 3: Advanced Verification (Weeks 7-9)
7. Physical music codes
8. Live setlist voting
9. AI photo verification (basic)

### Phase 4: Partnerships (Weeks 10-12)
10. Partner location network
11. Partner dashboard
12. Cross-promotion system

### Phase 5: MAINSTAGE Integration (Weeks 13-14)
13. Real-world scoring weights
14. "Real-World Champion" category
15. Combined analytics dashboard

---

## 11.11 Success Metrics

| Feature | Target Metric |
|---------|---------------|
| Merch verification | 20% of merch buyers register |
| Tip jar | 500 active buskers, $10k monthly tips |
| Setlist voting | 40% of checked-in fans vote |
| Physical releases | 15% registration rate |
| Lessons | 200 active teacher profiles |
| Jam sessions | 1,000 monthly verified jams |
| Photo verification | 80% AI accuracy |
| Partner check-ins | 50 partner locations, 5k monthly check-ins |

---

## 11.12 The Flywheel Effect

All these features create a virtuous cycle:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│     Fan discovers artist online (shorts, feed)              │
│                    ↓                                        │
│     Fan attends show (verified check-in)                    │
│                    ↓                                        │
│     Fan buys merch (verified registration)                  │
│                    ↓                                        │
│     Fan shares photo (AI verified)                          │
│                    ↓                                        │
│     Artist gains MAINSTAGE points                           │
│                    ↓                                        │
│     Artist ranks higher, more visibility                    │
│                    ↓                                        │
│     More fans discover artist online                        │
│                    ↓                                        │
│     (Cycle repeats, growing each time)                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**The key insight:** Every real-world interaction strengthens the digital connection, and every digital connection drives real-world action. This creates a platform that's impossible to replicate by competitors who only track one or the other.

---

# Part 12: Monetization Strategy

## 12.1 Core Philosophy

**"Free to thrive, pay to accelerate."**

The platform must remain valuable and fully functional for free users. Paid features should:
- Save time, not gate essential functionality
- Provide professional tools for serious users
- Never create a "pay-to-win" dynamic for MAINSTAGE
- Feel like a natural upgrade, not a restriction removal

### What Stays Free Forever

| Feature | Why It's Free |
|---------|---------------|
| Profile creation | Core value prop |
| Uploading shorts | Content is the platform |
| Following/followers | Network effects need scale |
| Basic analytics | Artists need to see growth |
| MAINSTAGE participation | Competition drives engagement |
| Check-ins & badges | Gamification needs mass adoption |
| Messaging (basic) | Communication is essential |
| Applying to gigs | Bands need opportunities |
| Fan features | Fans drive artist success |

---

## 12.2 Revenue Streams Overview

```
┌─────────────────────────────────────────────────────────────┐
│  KOKAI REVENUE MODEL                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Artist Subscriptions (PRO)         ~40% of revenue      │
│     └─ Monthly fee for professional tools                   │
│                                                             │
│  2. Industry Subscriptions (B2B)       ~25% of revenue      │
│     └─ Labels, agents, venues pay for discovery tools       │
│                                                             │
│  3. Transaction Fees                   ~20% of revenue      │
│     └─ Tips, merch, ticket sales, booking fees              │
│                                                             │
│  4. Promoted Content                   ~10% of revenue      │
│     └─ Artists pay for visibility boost                     │
│                                                             │
│  5. Premium Fan Features               ~5% of revenue       │
│     └─ Superfan perks and exclusive access                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 12.3 Artist PRO Subscription

### Pricing Tiers

| Tier | Price | Target User |
|------|-------|-------------|
| **Free** | $0/month | Hobbyists, new artists |
| **PRO** | $9.99/month | Serious independent artists |
| **PRO Band** | $19.99/month | Full bands (all members get PRO) |
| **PRO Annual** | $99/year | Committed artists (save 17%) |

### PRO Features

#### Analytics & Insights
| Feature | Free | PRO |
|---------|------|-----|
| Profile views (this week) | ✓ | ✓ |
| Profile views (all time + trends) | - | ✓ |
| Follower demographics (age, location) | - | ✓ |
| Best posting times | - | ✓ |
| Competitor benchmarking | - | ✓ |
| Export analytics to PDF/CSV | - | ✓ |
| Real-time engagement alerts | - | ✓ |

#### Profile Customization
| Feature | Free | PRO |
|---------|------|-----|
| Basic profile | ✓ | ✓ |
| Custom banner | ✓ | ✓ |
| Verified badge eligibility | - | ✓ |
| Custom profile URL (kokai.fm/yourname) | - | ✓ |
| Profile themes/colors | - | ✓ |
| Pinned shorts (up to 3) | 1 | 3 |
| Featured video autoplay | - | ✓ |
| Hide "Powered by Kokai" on embeds | - | ✓ |

#### Content Tools
| Feature | Free | PRO |
|---------|------|-----|
| Upload shorts | ✓ | ✓ |
| Schedule posts | - | ✓ |
| Draft saving | 3 | Unlimited |
| Video quality (upload) | 1080p | 4K |
| Longer shorts (up to 3 min) | - | ✓ |
| Watermark removal on downloads | - | ✓ |
| Bulk upload | - | ✓ |

#### Communication
| Feature | Free | PRO |
|---------|------|-----|
| DMs with fans | 20/day | Unlimited |
| Broadcast messages to followers | - | ✓ |
| Auto-reply setup | - | ✓ |
| Priority inbox (industry contacts first) | - | ✓ |

#### MAINSTAGE & Competitions
| Feature | Free | PRO |
|---------|------|-----|
| Participate in MAINSTAGE | ✓ | ✓ |
| See detailed score breakdown | - | ✓ |
| Historical ranking trends | - | ✓ |
| Personalized tips to improve rank | - | ✓ |

#### Real-World Tools
| Feature | Free | PRO |
|---------|------|-----|
| Gig check-in visibility | ✓ | ✓ |
| Proof of Draw report | Basic | Detailed PDF |
| Merch code generation | 50/month | Unlimited |
| Tip jar (transaction fee) | 10% | 5% |
| Live setlist polling | - | ✓ |

### PRO Value Proposition

```
┌─────────────────────────────────────────────────────────────┐
│  🎸 UPGRADE TO PRO                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  You're leaving opportunities on the table.                 │
│                                                             │
│  This week you missed:                                      │
│  • 47 profile views you can't analyze                       │
│  • 3 industry professionals who viewed your profile         │
│  • The best time to post (your fans are most active at 8pm) │
│                                                             │
│  PRO artists grow 3x faster on average.                     │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  $9.99/month • Cancel anytime                       │   │
│  │  [Start 14-Day Free Trial]                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 12.4 Industry Subscriptions (B2B)

Already detailed in Part 7, but summarized here:

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | Browse public profiles, basic search |
| **Pro** | $75/month | Advanced search, watchlists, contact artists |
| **Enterprise** | $500+/month | API access, custom reports, A&R alerts |

### Revenue Potential

- 500 Pro subscribers = $37,500/month
- 50 Enterprise subscribers = $25,000+/month
- **Total B2B potential: $60,000+/month**

---

## 12.5 Transaction Fees

Take a small cut of money flowing through the platform.

### Fee Structure

| Transaction Type | Platform Fee | Notes |
|------------------|--------------|-------|
| Tips (free users) | 10% | Incentive to go PRO |
| Tips (PRO users) | 5% | PRO benefit |
| Merch sales | 8% | If using native store |
| Ticket sales | 5% + $0.50 | For gigs booked through platform |
| Booking deposits | 3% | When bands get booked via platform |
| Lesson payments | 10% | If booked through platform |

### Why This Works

- Fans are used to transaction fees (Venmo, PayPal, etc.)
- Artists accept fees when the platform brings them business
- Lower fees than competitors (Bandcamp takes 15%, Patreon 8-12%)

### Revenue Projections

| Scenario | Monthly GMV | Platform Revenue |
|----------|-------------|------------------|
| Year 1 | $50,000 | $3,500 |
| Year 2 | $500,000 | $35,000 |
| Year 3 | $2,000,000 | $140,000 |

---

## 12.6 Promoted Content

Artists pay to boost visibility without gaming MAINSTAGE.

### Promotion Types

#### 1. Promoted Shorts
- Appears in "Discover" feed with "Promoted" label
- Targeted by genre, location, or interests
- **Pricing:** $5-50/day depending on reach

#### 2. Featured Profile
- Appears in "Featured Artists" section
- Homepage visibility for 24 hours
- **Pricing:** $25/day (limited slots)

#### 3. Gig Promotion
- Boost upcoming gig to local users
- Push notification to followers + nearby users
- **Pricing:** $10-30 per gig

#### 4. Challenge Sponsorship
- Sponsor a challenge with your branding
- Your short as the "original" challenge starter
- **Pricing:** $100-500 depending on engagement guarantee

### Promotion Rules

**Critical:** Promoted content NEVER affects MAINSTAGE scoring.
- Paid engagement doesn't count toward scores
- Clear "Promoted" labels maintain trust
- Organic engagement on promoted content does count

### Self-Serve Ad Platform

```
┌─────────────────────────────────────────────────────────────┐
│  📢 PROMOTE YOUR SHORT                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Select a short to promote:                                 │
│  [Dropdown: "Jazz Improv Session" ▼]                        │
│                                                             │
│  Target Audience:                                           │
│  ☑ Jazz fans       ☑ Guitar enthusiasts                    │
│  ☐ Rock fans       ☐ Drummers                               │
│                                                             │
│  Location:                                                  │
│  [Los Angeles area (25 mile radius) ▼]                      │
│                                                             │
│  Budget:                                                    │
│  [$20_____] per day × [3___] days = $60 total              │
│                                                             │
│  Estimated reach: 2,500 - 4,000 users                       │
│                                                             │
│  [Launch Promotion]                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 12.7 Premium Fan Features (Fan PRO)

Superfans can pay for enhanced experiences.

### Fan PRO Subscription

**Price:** $4.99/month

| Feature | Free Fan | Fan PRO |
|---------|----------|---------|
| Follow artists | ✓ | ✓ |
| Like/comment | ✓ | ✓ |
| Ad-free experience | - | ✓ |
| Early access to shorts | - | ✓ (24 hours before) |
| Exclusive "PRO Fan" badge | - | ✓ |
| Double points on all actions | - | ✓ |
| Priority in artist giveaways | - | ✓ |
| See who else is at shows | Basic | Detailed |
| Custom profile themes | - | ✓ |
| Download shorts for offline | - | ✓ |

### Why Fans Would Pay

- **Superfan identity**: Badge shows dedication
- **Double points**: Faster badge/reward progression
- **Early access**: See new content before others
- **No ads**: Clean, distraction-free experience

---

## 12.8 Venue & Promoter Subscriptions

Venues and promoters get their own tier.

### Venue PRO

**Price:** $49/month

| Feature | Free | Venue PRO |
|---------|------|-----------|
| List venue on platform | ✓ | ✓ |
| Receive band applications | ✓ | ✓ |
| Analytics on check-ins | Basic | Detailed |
| QR code check-in system | - | ✓ |
| See fan demographics | - | ✓ |
| Priority in "Venues Near Me" | - | ✓ |
| Booking management tools | - | ✓ |
| Artist comparison reports | - | ✓ |
| White-label check-in page | - | ✓ |

### Value for Venues

- Know exactly who's coming to shows
- Compare artist draw power before booking
- Build direct relationship with local fans
- Prove venue popularity to sponsors

---

## 12.9 Kokai Credits (Virtual Currency)

Optional virtual currency for microtransactions.

### How It Works

1. Users buy credits ($1 = 100 credits)
2. Credits used for small transactions
3. Bonus credits for larger purchases

### Credit Packages

| Package | Price | Credits | Bonus |
|---------|-------|---------|-------|
| Starter | $5 | 500 | - |
| Popular | $20 | 2,200 | +10% |
| Best Value | $50 | 6,000 | +20% |

### What Credits Buy

- Tip artists in any amount (no minimum)
- Boost a comment (appear first)
- Send "super likes" (artist gets notified)
- Entry to exclusive contests
- Virtual gifts during live streams (future feature)

### Why Virtual Currency

- Reduces transaction fees (batch purchases)
- Encourages spending ("I have credits, might as well use them")
- Enables microtransactions (<$1)
- Creates engagement loop

---

## 12.10 Partnerships & Sponsorships

### Brand Partnerships

| Partner Type | Integration | Revenue |
|--------------|-------------|---------|
| Instrument brands | "Gear of the Week" sponsored feature | $5-20k/month |
| Music software | Exclusive deals for PRO users | Revenue share |
| Streaming services | Cross-promotion | Per-signup bounty |
| Music schools | Student/teacher verification | Referral fees |

### Event Sponsorships

- MAINSTAGE presented by [Brand]
- Challenge of the Week sponsored by [Brand]
- "Rising Star" award sponsored by [Brand]

### Affiliate Revenue

- Recommend gear mentioned in shorts (Amazon affiliate)
- Link to Spotify/Apple Music (streaming payouts)
- Ticket sales affiliate (Eventbrite, DICE)

---

## 12.11 Database Schema for Monetization

#### `subscriptions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| plan_type | string | `artist_pro`, `band_pro`, `fan_pro`, `venue_pro`, `industry_pro`, `industry_enterprise` |
| status | string | `active`, `canceled`, `past_due`, `trialing` |
| stripe_subscription_id | string | |
| current_period_start | datetime | |
| current_period_end | datetime | |
| cancel_at_period_end | boolean | |
| created_at | datetime | |

#### `transactions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| sender_id | bigint | User paying |
| recipient_id | bigint | User receiving |
| transaction_type | string | `tip`, `merch`, `ticket`, `booking`, `lesson` |
| gross_amount_cents | integer | |
| platform_fee_cents | integer | |
| net_amount_cents | integer | |
| stripe_payment_id | string | |
| status | string | `pending`, `completed`, `refunded` |
| created_at | datetime | |

#### `promotions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Artist promoting |
| promotable_type | string | `MusicianShort`, `Gig`, `Musician` |
| promotable_id | bigint | |
| budget_cents | integer | |
| spent_cents | integer | |
| target_genres | string[] | |
| target_location | string | |
| target_radius_km | integer | |
| impressions | integer | |
| clicks | integer | |
| status | string | `active`, `paused`, `completed`, `exhausted` |
| starts_at | datetime | |
| ends_at | datetime | |
| created_at | datetime | |

#### `credit_balances`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| balance | integer | Current credits |
| lifetime_purchased | integer | |
| lifetime_spent | integer | |
| updated_at | datetime | |

#### `credit_transactions`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | |
| amount | integer | Positive = earned/bought, negative = spent |
| transaction_type | string | `purchase`, `tip_sent`, `tip_received`, `boost`, `gift` |
| reference_type | string | |
| reference_id | bigint | |
| created_at | datetime | |

---

## 12.12 Pricing Psychology

### Anchor Pricing

Show the most expensive option first:
```
┌─────────────────────────────────────────────────────────────┐
│  Choose Your Plan                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ PRO ANNUAL  │ │ PRO MONTHLY │ │    FREE     │           │
│  │             │ │             │ │             │           │
│  │   $99/yr    │ │ $9.99/mo    │ │    $0       │           │
│  │  BEST VALUE │ │             │ │             │           │
│  │             │ │             │ │             │           │
│  │ Save $21    │ │ Most        │ │ Limited     │           │
│  │ vs monthly  │ │ Flexible    │ │ Features    │           │
│  │             │ │             │ │             │           │
│  │ [Choose]    │ │ [Choose]    │ │ [Stay Free] │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Conversion Triggers

1. **Milestone-based**: "You hit 100 followers! Unlock insights with PRO"
2. **FOMO**: "3 industry professionals viewed your profile this week"
3. **Feature discovery**: "You tried to schedule a post. That's a PRO feature!"
4. **Social proof**: "Top artists on MAINSTAGE are 5x more likely to be PRO"
5. **Time-limited**: "First month 50% off - expires in 48 hours"

### Free Trial Strategy

- 14-day free trial for Artist PRO
- No credit card required to start
- Day 10: "Your trial ends in 4 days, here's what you'll lose"
- Day 13: "Last chance! Keep your analytics history"
- Day 14: Downgrade, but show "What you're missing" weekly

---

## 12.13 Revenue Projections

### Year 1 (Launch + Growth)

| Revenue Stream | Monthly | Annual |
|----------------|---------|--------|
| Artist PRO (500 @ $10) | $5,000 | $60,000 |
| Industry Pro (50 @ $75) | $3,750 | $45,000 |
| Transaction fees | $3,500 | $42,000 |
| Promoted content | $2,000 | $24,000 |
| Fan PRO (200 @ $5) | $1,000 | $12,000 |
| **Total Year 1** | **$15,250** | **$183,000** |

### Year 2 (Traction)

| Revenue Stream | Monthly | Annual |
|----------------|---------|--------|
| Artist PRO (3,000 @ $10) | $30,000 | $360,000 |
| Industry Pro (200 @ $75) | $15,000 | $180,000 |
| Industry Enterprise (20 @ $500) | $10,000 | $120,000 |
| Transaction fees | $35,000 | $420,000 |
| Promoted content | $15,000 | $180,000 |
| Fan PRO (2,000 @ $5) | $10,000 | $120,000 |
| Venue PRO (100 @ $49) | $4,900 | $58,800 |
| **Total Year 2** | **$119,900** | **$1,438,800** |

### Year 3 (Scale)

| Revenue Stream | Monthly | Annual |
|----------------|---------|--------|
| Artist PRO (15,000 @ $10) | $150,000 | $1,800,000 |
| Industry subscriptions | $75,000 | $900,000 |
| Transaction fees | $140,000 | $1,680,000 |
| Promoted content | $60,000 | $720,000 |
| Fan PRO (10,000 @ $5) | $50,000 | $600,000 |
| Venue PRO (500 @ $49) | $24,500 | $294,000 |
| Partnerships | $25,000 | $300,000 |
| **Total Year 3** | **$524,500** | **$6,294,000** |

---

## 12.14 Competitive Pricing Analysis

### vs. Competitors

| Platform | Artist Cost | What You Get |
|----------|-------------|--------------|
| **Kokai PRO** | $9.99/mo | Full analytics, scheduling, verified badge, lower fees |
| Bandcamp Pro | $10/mo | Just basic stats and batch downloads |
| Linktree Pro | $9/mo | Just link management |
| Patreon | 8-12% of revenue | Just payment processing |
| DistroKid | $22.99/yr | Just distribution |

### Our Advantage

Kokai PRO gives you analytics + promotion + booking + real-world verification all in one place. Competitors would cost $50+/month combined.

---

## 12.15 Implementation Phases

### Phase 1: Foundation (Months 1-2)
1. Stripe integration for payments
2. Basic Artist PRO subscription
3. Transaction fee infrastructure

### Phase 2: Expansion (Months 3-4)
4. Industry subscriptions (Pro tier)
5. Venue PRO tier
6. Fan PRO tier

### Phase 3: Advanced (Months 5-6)
7. Self-serve promotion platform
8. Kokai Credits system
9. Industry Enterprise tier

### Phase 4: Optimization (Months 7-8)
10. A/B test pricing
11. Conversion optimization
12. Partnership integrations

---

## 12.16 Key Metrics to Track

| Metric | Target |
|--------|--------|
| Free → PRO conversion | 5-8% |
| PRO churn rate | <5%/month |
| Average revenue per user (ARPU) | $2.50 |
| Lifetime value (LTV) | $150 |
| Customer acquisition cost (CAC) | <$30 |
| LTV:CAC ratio | >5:1 |
| Transaction GMV growth | 20%/month |
| Promotion fill rate | 80% |

---

## 12.17 Anti-Patterns to Avoid

### What We Will NEVER Do

1. **Pay-to-win MAINSTAGE**: Paying never affects rankings
2. **Essential feature gating**: Free users can still succeed
3. **Hidden fees**: All costs clearly disclosed
4. **Aggressive upselling**: Prompts are helpful, not annoying
5. **Data selling**: User data is never sold to third parties
6. **Exclusive content lockout**: Fans can always see artist content
7. **Communication blocking**: Free users can always message (with limits)

### Why This Matters

Trust is everything. If users feel nickel-and-dimed, they leave. If free users feel like second-class citizens, they won't invite friends. The platform only works at scale, and scale requires trust.
