class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :kanban_tasks, foreign_key: :created_by_id, dependent: :destroy
  has_many :bands, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :chats, through: :participations
  has_many :messages, dependent: :destroy
  has_many :venues, dependent: :destroy
  # has_many :musicians, dependent: :destroy #A user can only have one musician, itself right?
  has_many :gigs, through: :venues
  has_many :bookings, through: :bands
  has_many :message_reads
  has_many :read_messages, through: :message_reads, source: :message
  has_one :musician, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :short_likes, dependent: :destroy
  has_many :liked_shorts, through: :short_likes, source: :musician_short
  has_many :short_comments, dependent: :destroy
  has_many :follows, foreign_key: :follower_id, dependent: :destroy # Follows initiated by this user
  has_many :followed_musicians, through: :follows, source: :followable, source_type: 'Musician' # Musicians this user follows
  has_many :followed_bands, through: :follows, source: :followable, source_type: 'Band' # Bands this user follows
  has_many :profile_saves, class_name: 'ProfileSave', dependent: :destroy
  has_many :saved_musicians, through: :profile_saves, source: :saveable, source_type: 'Musician'
  has_many :saved_bands, through: :profile_saves, source: :saveable, source_type: 'Band'
  has_many :sent_friend_requests, class_name: 'Friendship', foreign_key: :requester_id, dependent: :destroy
  has_many :received_friend_requests, class_name: 'Friendship', foreign_key: :addressee_id, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :reposts, dependent: :destroy
  has_many :reposted_posts, through: :reposts, source: :post
  has_many :post_likes, dependent: :destroy
  has_many :liked_posts, through: :post_likes, source: :post
  has_many :post_comments, dependent: :destroy
  has_many :endorsements, dependent: :destroy
  has_many :endorsed_musicians, through: :endorsements, source: :musician
  has_many :shoutouts, dependent: :destroy
  has_many :shouted_out_musicians, through: :shoutouts, source: :musician
  has_many :activities, dependent: :destroy
  has_many :challenge_votes, dependent: :destroy
  has_many :gig_attendances, dependent: :destroy
  has_many :attending_gigs, through: :gig_attendances, source: :gig
  has_many :led_bands, class_name: 'Band', foreign_key: 'user_id'
  has_one :fan, dependent: :destroy

  # convenience: check roles
  def musician?
    user_type == "musician"
  end

  def band_leader?
    user_type == "band_leader"
  end


  def direct_message_chats
    chats.direct_messages.includes(:messages, :users)
  end

  def unread_dm_count
    MessageRead.joins(:message)
      .where(user_id: id, read: false)
      .where(messages: { chat_id: chats.direct_messages.pluck(:id) })
      .count
  end

  def chat_with(other_user)
    Chat.between(self, other_user)
  end

   def friends
    accepted_sent = sent_friend_requests.accepted.pluck(:addressee_id)
    accepted_received = received_friend_requests.accepted.pluck(:requester_id)
    User.where(id: accepted_sent + accepted_received)
   end

  def pending_friend_requests
    received_friend_requests.pending
  end

  def friend_with?(user)
    friends.include?(user)
  end

  def feed
    # Get posts from: self, friends, followed musicians' users, and followed bands
    friend_ids = friends.pluck(:id)
    followed_user_ids = followed_musicians.joins(:user).pluck('users.id')
    all_user_ids = ([id] + friend_ids + followed_user_ids).uniq

    # Get IDs of bands the user follows
    followed_band_ids = followed_bands.pluck(:id)

    # Get original posts (personal posts from users + posts from followed bands)
    personal_posts = Post.where(user_id: all_user_ids, band_id: nil)
    band_posts = Post.where(band_id: followed_band_ids)
    original_post_ids = personal_posts.pluck(:id) + band_posts.pluck(:id)

    # Get reposts
    reposted_post_ids = Repost.where(user_id: all_user_ids).pluck(:post_id)

    Post.where(id: original_post_ids + reposted_post_ids).distinct.recent
  end
end
