class Post < ApplicationRecord
  belongs_to :user
  belongs_to :band, optional: true  # Optional - only set for band posts
  has_many :reposts, dependent: :destroy
  has_many :reposted_by_users, through: :reposts, source: :user
  has_many :post_likes, dependent: :destroy
  has_many :likers, through: :post_likes, source: :user
  has_many :post_comments, dependent: :destroy
  has_many_attached :images
  has_many_attached :videos

  validates :content, presence: true, unless: -> { images.attached? || videos.attached? }

  scope :recent, -> { order(created_at: :desc) }
  scope :band_posts, -> { where.not(band_id: nil) }
  scope :personal_posts, -> { where(band_id: nil) }
  scope :active_requests, -> { where(active: true).where('needed_by >= ?', Date.current)}
  scope :by_instrument, -> { where(instrument: instrument) if instrument.present? }
  scope :by_location, ->(location) { where('location ILIKE ?', "%#{location}%") if location.present? }
  scope :by_genre, ->(genre) { where('genre ILIKE ?', "%#{genre}%") if genre.present? }



  def self.expire_old_posts
    where('needed_by < ?', Date.current).update_all(active: false)
  end

   def matches_musician?(musician)
    return false unless musician
    matches = true
    matches &&= (instrument.blank? || musician.instrument&.downcase == instrument&.downcase)
    matches &&= (location.blank? || musician.location&.downcase&.include?(location&.downcase))
    matches
   end
  # Returns the display name for the post author
  def author_name
    if band.present?
      band.name
    elsif user.musician.present?
      user.musician.name
    else
      user.username
    end
  end

  # Returns true if this is a band post
  def band_post?
    band_id.present?
  end

  def reposted_by?(user)
    return false unless user
    reposts.exists?(user: user)
  end

  def liked_by?(user)
    return false unless user
    post_likes.exists?(user: user)
  end
end
