# MAINSTAGE & Engagement Features

## Overview

MAINSTAGE is a weekly contest that showcases artists with the highest overall engagement on the platform. Unlike simple "most liked video" contests, MAINSTAGE rewards musicians and bands who build genuine connections across the entire site.

This document also covers the engagement features needed to drive traffic from fans (not just musicians) and create a thriving community.

---

# Part 1: Engagement Features

## 1.1 Follow System

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

## 1.2 Profile View Tracking

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

## 1.3 Profile Saves/Bookmarks

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
