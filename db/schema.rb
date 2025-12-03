# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_03_030722) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "trackable_type", null: false
    t.bigint "trackable_id", null: false
    t.bigint "musician_id"
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["musician_id", "created_at"], name: "index_activities_on_musician_id_and_created_at"
    t.index ["musician_id"], name: "index_activities_on_musician_id"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "attachments", force: :cascade do |t|
    t.string "file_url"
    t.string "file_name"
    t.string "file_type"
    t.bigint "message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_attachments_on_message_id"
  end

  create_table "band_events", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.string "title"
    t.integer "event_type"
    t.date "date"
    t.time "start_time"
    t.time "end_time"
    t.string "location"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_band_events_on_band_id"
  end

  create_table "band_invitations", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.bigint "musician_id", null: false
    t.bigint "inviter_id"
    t.string "status"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_band_invitations_on_band_id"
    t.index ["inviter_id"], name: "index_band_invitations_on_inviter_id"
    t.index ["musician_id"], name: "index_band_invitations_on_musician_id"
  end

  create_table "band_mainstage_contests", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_date", "end_date"], name: "index_band_mainstage_contests_on_start_date_and_end_date"
    t.index ["status"], name: "index_band_mainstage_contests_on_status"
  end

  create_table "band_mainstage_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "band_id", null: false
    t.bigint "band_mainstage_contest_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_band_mainstage_votes_on_band_id"
    t.index ["band_mainstage_contest_id"], name: "index_band_mainstage_votes_on_band_mainstage_contest_id"
    t.index ["user_id", "band_mainstage_contest_id"], name: "idx_band_mainstage_votes_user_contest", unique: true
    t.index ["user_id"], name: "index_band_mainstage_votes_on_user_id"
  end

  create_table "band_mainstage_winners", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.bigint "band_mainstage_contest_id", null: false
    t.integer "final_score", default: 0
    t.integer "engagement_score", default: 0
    t.integer "vote_score", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_band_mainstage_winners_on_band_id"
    t.index ["band_mainstage_contest_id"], name: "idx_band_mainstage_winners_contest", unique: true
  end

  create_table "bands", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.integer "banner_position", default: 50
    t.string "instagram_handle"
    t.integer "instagram_followers", default: 0
    t.string "tiktok_handle"
    t.integer "tiktok_followers", default: 0
    t.string "youtube_handle"
    t.integer "youtube_subscribers", default: 0
    t.string "twitter_handle"
    t.integer "twitter_followers", default: 0
    t.index ["user_id"], name: "index_bands_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.text "message"
    t.text "status"
    t.bigint "band_id", null: false
    t.bigint "gig_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_bookings_on_band_id"
    t.index ["gig_id"], name: "index_bookings_on_gig_id"
  end

  create_table "challenge_responses", force: :cascade do |t|
    t.bigint "challenge_id", null: false
    t.bigint "musician_short_id", null: false
    t.bigint "musician_id", null: false
    t.integer "votes_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id", "musician_id"], name: "index_challenge_responses_on_challenge_id_and_musician_id", unique: true
    t.index ["challenge_id"], name: "index_challenge_responses_on_challenge_id"
    t.index ["musician_id"], name: "index_challenge_responses_on_musician_id"
    t.index ["musician_short_id"], name: "index_challenge_responses_on_musician_short_id"
  end

  create_table "challenge_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "challenge_response_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_response_id"], name: "index_challenge_votes_on_challenge_response_id"
    t.index ["user_id", "challenge_response_id"], name: "index_challenge_votes_on_user_id_and_challenge_response_id", unique: true
    t.index ["user_id"], name: "index_challenge_votes_on_user_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.bigint "original_short_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "open", null: false
    t.bigint "winner_id"
    t.integer "responses_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_challenges_on_creator_id"
    t.index ["original_short_id"], name: "index_challenges_on_original_short_id"
    t.index ["status"], name: "index_challenges_on_status"
  end

  create_table "chats", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "band_id"
    t.index ["band_id"], name: "index_chats_on_band_id"
  end

  create_table "endorsements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "musician_id", null: false
    t.string "skill", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["musician_id"], name: "index_endorsements_on_musician_id"
    t.index ["user_id", "musician_id", "skill"], name: "index_endorsements_on_user_id_and_musician_id_and_skill", unique: true
    t.index ["user_id"], name: "index_endorsements_on_user_id"
  end

  create_table "fans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "display_name"
    t.text "bio"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "favorite_genres"
    t.string "social_instagram"
    t.string "social_twitter"
    t.string "social_spotify"
    t.index ["user_id"], name: "index_fans_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.string "followable_type", null: false
    t.bigint "followable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable_type_and_followable_id"
    t.index ["follower_id", "followable_type", "followable_id"], name: "index_follows_on_uniqueness", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.bigint "requester_id", null: false
    t.bigint "addressee_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addressee_id"], name: "index_friendships_on_addressee_id"
    t.index ["requester_id", "addressee_id"], name: "index_friendships_on_requester_id_and_addressee_id", unique: true
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
    t.index ["status"], name: "index_friendships_on_status"
  end

  create_table "gig_applications", force: :cascade do |t|
    t.bigint "gig_id", null: false
    t.bigint "band_id", null: false
    t.integer "status", default: 0
    t.text "message"
    t.text "response_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_gig_applications_on_band_id"
    t.index ["gig_id", "band_id"], name: "index_gig_applications_on_gig_id_and_band_id", unique: true
    t.index ["gig_id"], name: "index_gig_applications_on_gig_id"
  end

  create_table "gig_attendances", force: :cascade do |t|
    t.bigint "gig_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gig_id", "user_id"], name: "index_gig_attendances_on_gig_id_and_user_id", unique: true
    t.index ["gig_id"], name: "index_gig_attendances_on_gig_id"
    t.index ["user_id"], name: "index_gig_attendances_on_user_id"
  end

  create_table "gigs", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.text "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.time "start_time"
    t.time "end_time"
    t.decimal "ticket_price"
    t.text "description"
    t.string "genre"
    t.index ["venue_id"], name: "index_gigs_on_venue_id"
  end

  create_table "involvements", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.bigint "musician_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id", "musician_id"], name: "index_involvements_on_band_and_musician_unique", unique: true
    t.index ["band_id"], name: "index_involvements_on_band_id"
    t.index ["musician_id"], name: "index_involvements_on_musician_id"
  end

  create_table "kanban_tasks", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "to_do", null: false
    t.bigint "created_by_id", null: false
    t.string "task_type", null: false
    t.date "deadline"
    t.text "description"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "band_id"
    t.bigint "assigned_to_id"
    t.index ["assigned_to_id"], name: "index_kanban_tasks_on_assigned_to_id"
    t.index ["band_id"], name: "index_kanban_tasks_on_band_id"
    t.index ["created_by_id"], name: "index_kanban_tasks_on_created_by_id"
    t.index ["deadline"], name: "index_kanban_tasks_on_deadline"
    t.index ["status"], name: "index_kanban_tasks_on_status"
    t.index ["task_type"], name: "index_kanban_tasks_on_task_type"
  end

  create_table "mainstage_contests", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_date", "end_date"], name: "index_mainstage_contests_on_start_date_and_end_date"
    t.index ["status"], name: "index_mainstage_contests_on_status"
  end

  create_table "mainstage_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "musician_id", null: false
    t.bigint "mainstage_contest_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mainstage_contest_id"], name: "index_mainstage_votes_on_mainstage_contest_id"
    t.index ["musician_id"], name: "index_mainstage_votes_on_musician_id"
    t.index ["user_id", "mainstage_contest_id"], name: "index_mainstage_votes_on_user_id_and_mainstage_contest_id", unique: true
    t.index ["user_id"], name: "index_mainstage_votes_on_user_id"
  end

  create_table "mainstage_winners", force: :cascade do |t|
    t.bigint "musician_id", null: false
    t.bigint "mainstage_contest_id", null: false
    t.integer "final_score", default: 0
    t.integer "engagement_score", default: 0
    t.integer "vote_score", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mainstage_contest_id"], name: "index_mainstage_winners_on_mainstage_contest_id", unique: true
    t.index ["musician_id"], name: "index_mainstage_winners_on_musician_id"
  end

  create_table "member_availabilities", force: :cascade do |t|
    t.bigint "musician_id", null: false
    t.bigint "band_id", null: false
    t.date "start_date"
    t.integer "status"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "end_date"
    t.index ["band_id"], name: "index_member_availabilities_on_band_id"
    t.index ["musician_id"], name: "index_member_availabilities_on_musician_id"
  end

  create_table "message_reads", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "user_id", null: false
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id"], name: "index_message_reads_on_message_and_user_unique", unique: true
    t.index ["message_id"], name: "index_message_reads_on_message_id"
    t.index ["user_id"], name: "index_message_reads_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "chat_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "musician_shorts", force: :cascade do |t|
    t.bigint "musician_id", null: false
    t.string "title"
    t.text "description"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["musician_id"], name: "index_musician_shorts_on_musician_id"
  end

  create_table "musicians", force: :cascade do |t|
    t.string "name"
    t.string "instrument"
    t.integer "age"
    t.string "styles"
    t.string "location"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "bio"
    t.integer "banner_position"
    t.string "status"
    t.index ["user_id"], name: "index_musicians_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.string "notification_type", null: false
    t.text "message"
    t.boolean "read", default: false, null: false
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_participations_on_chat_id"
    t.index ["user_id", "chat_id"], name: "index_participations_on_user_and_chat_unique", unique: true
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "post_comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_comments_on_post_id"
    t.index ["user_id"], name: "index_post_comments_on_user_id"
  end

  create_table "post_likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_likes_on_post_id"
    t.index ["user_id", "post_id"], name: "index_post_likes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_post_likes_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "band_id"
    t.string "instrument"
    t.string "location"
    t.string "genre"
    t.date "needed_by"
    t.boolean "active", default: true
    t.index ["active"], name: "index_posts_on_active"
    t.index ["band_id"], name: "index_posts_on_band_id"
    t.index ["needed_by"], name: "index_posts_on_needed_by"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "profile_saves", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "saveable_type", null: false
    t.bigint "saveable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["saveable_type", "saveable_id"], name: "index_profile_saves_on_saveable_type_and_saveable_id"
    t.index ["user_id", "saveable_type", "saveable_id"], name: "index_profile_saves_uniqueness", unique: true
    t.index ["user_id"], name: "index_profile_saves_on_user_id"
  end

  create_table "profile_views", force: :cascade do |t|
    t.bigint "viewer_id"
    t.string "viewable_type", null: false
    t.bigint "viewable_id", null: false
    t.datetime "viewed_at", null: false
    t.string "ip_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["viewable_type", "viewable_id", "viewed_at"], name: "index_profile_views_on_viewable_and_time"
    t.index ["viewer_id"], name: "index_profile_views_on_viewer_id"
  end

  create_table "reposts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_reposts_on_post_id"
    t.index ["user_id", "post_id"], name: "index_reposts_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_reposts_on_user_id"
  end

  create_table "short_comments", force: :cascade do |t|
    t.bigint "musician_short_id", null: false
    t.bigint "user_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["musician_short_id"], name: "index_short_comments_on_musician_short_id"
    t.index ["user_id"], name: "index_short_comments_on_user_id"
  end

  create_table "short_likes", force: :cascade do |t|
    t.bigint "musician_short_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["musician_short_id", "user_id"], name: "index_short_likes_on_musician_short_id_and_user_id", unique: true
    t.index ["musician_short_id"], name: "index_short_likes_on_musician_short_id"
    t.index ["user_id"], name: "index_short_likes_on_user_id"
  end

  create_table "shoutouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "musician_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["musician_id"], name: "index_shoutouts_on_musician_id"
    t.index ["user_id"], name: "index_shoutouts_on_user_id"
  end

  create_table "spotify_tracks", force: :cascade do |t|
    t.bigint "band_id", null: false
    t.string "spotify_type"
    t.string "spotify_id"
    t.string "spotify_url"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_spotify_tracks_on_band_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "user_type"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "city"
    t.integer "capacity"
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.integer "banner_position"
    t.index ["user_id"], name: "index_venues_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "musicians"
  add_foreign_key "activities", "users"
  add_foreign_key "attachments", "messages"
  add_foreign_key "band_events", "bands"
  add_foreign_key "band_invitations", "bands"
  add_foreign_key "band_invitations", "musicians"
  add_foreign_key "band_invitations", "users", column: "inviter_id"
  add_foreign_key "band_mainstage_votes", "band_mainstage_contests"
  add_foreign_key "band_mainstage_votes", "bands"
  add_foreign_key "band_mainstage_votes", "users"
  add_foreign_key "band_mainstage_winners", "band_mainstage_contests"
  add_foreign_key "band_mainstage_winners", "bands"
  add_foreign_key "bands", "users"
  add_foreign_key "bookings", "bands"
  add_foreign_key "bookings", "gigs"
  add_foreign_key "challenge_responses", "challenges"
  add_foreign_key "challenge_responses", "musician_shorts"
  add_foreign_key "challenge_responses", "musicians"
  add_foreign_key "challenge_votes", "challenge_responses"
  add_foreign_key "challenge_votes", "users"
  add_foreign_key "challenges", "musician_shorts", column: "original_short_id"
  add_foreign_key "challenges", "musicians", column: "creator_id"
  add_foreign_key "chats", "bands"
  add_foreign_key "endorsements", "musicians"
  add_foreign_key "endorsements", "users"
  add_foreign_key "fans", "users"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "friendships", "users", column: "addressee_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "gig_applications", "bands"
  add_foreign_key "gig_applications", "gigs"
  add_foreign_key "gig_attendances", "gigs"
  add_foreign_key "gig_attendances", "users"
  add_foreign_key "gigs", "venues"
  add_foreign_key "involvements", "bands"
  add_foreign_key "involvements", "musicians"
  add_foreign_key "kanban_tasks", "bands"
  add_foreign_key "kanban_tasks", "musicians", column: "assigned_to_id"
  add_foreign_key "kanban_tasks", "users", column: "created_by_id"
  add_foreign_key "mainstage_votes", "mainstage_contests"
  add_foreign_key "mainstage_votes", "musicians"
  add_foreign_key "mainstage_votes", "users"
  add_foreign_key "mainstage_winners", "mainstage_contests"
  add_foreign_key "mainstage_winners", "musicians"
  add_foreign_key "member_availabilities", "bands"
  add_foreign_key "member_availabilities", "musicians"
  add_foreign_key "message_reads", "messages"
  add_foreign_key "message_reads", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "users"
  add_foreign_key "musician_shorts", "musicians"
  add_foreign_key "musicians", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "participations", "chats"
  add_foreign_key "participations", "users"
  add_foreign_key "post_comments", "posts"
  add_foreign_key "post_comments", "users"
  add_foreign_key "post_likes", "posts"
  add_foreign_key "post_likes", "users"
  add_foreign_key "posts", "bands"
  add_foreign_key "posts", "users"
  add_foreign_key "profile_saves", "users"
  add_foreign_key "profile_views", "users", column: "viewer_id", on_delete: :nullify
  add_foreign_key "reposts", "posts"
  add_foreign_key "reposts", "users"
  add_foreign_key "short_comments", "musician_shorts"
  add_foreign_key "short_comments", "users"
  add_foreign_key "short_likes", "musician_shorts"
  add_foreign_key "short_likes", "users"
  add_foreign_key "shoutouts", "musicians"
  add_foreign_key "shoutouts", "users"
  add_foreign_key "spotify_tracks", "bands"
  add_foreign_key "taggings", "tags"
  add_foreign_key "venues", "users"
end
