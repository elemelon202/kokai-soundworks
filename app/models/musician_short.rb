class MusicianShort < ApplicationRecord
  belongs_to :musician
  has_one_attached :video
  has_many :short_likes, dependent: :destroy
  has_many :likers, through: :short_likes, source: :user
  has_many :short_comments, dependent: :destroy
  has_many :challenges, foreign_key: :original_short_id, dependent: :destroy
  has_one :challenge_response, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :video, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :acceptable_video

  default_scope { order(position: :asc, created_at: :desc) }

  private

  def acceptable_video
    return unless video.attached?

    unless video.content_type.in?(%w[video/mp4 video/quicktime])
      errors.add(:video, 'must be an MP4 or MOV file')
    end

    if video.byte_size > 200.megabytes
      errors.add(:video, 'is too large. Maximum size is 200MB.')
    end
  end
end
