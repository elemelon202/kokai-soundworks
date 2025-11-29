class Shoutout < ApplicationRecord
  belongs_to :user
  belongs_to :musician

  validates :content, presence: true, length: { maximum: 500 }
  validates :user_id, uniqueness: { scope: :musician_id, message: "can only give one shoutout per musician" }

  scope :recent, -> { order(created_at: :desc) }
end
