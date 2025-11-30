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
