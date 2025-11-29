class Post < ApplicationRecord
  belongs_to :user
  has_many :reposts, dependent: :destroy
  has_many :reposted_by_users, through: :reposts, source: :user
  has_many :post_likes, dependent: :destroy
  has_many :likers, through: :post_likes, source: :user
  has_many :post_comments, dependent: :destroy
  has_many_attached :images
  has_many_attached :videos

  validates :content, presence: true, unless: -> { images.attached? || videos.attached? }

  scope :recent, -> { order(created_at: :desc) }

  def reposted_by?(user)
    return false unless user
    reposts.exists?(user: user)
  end

  def liked_by?(user)
    return false unless user
    post_likes.exists?(user: user)
  end
end
