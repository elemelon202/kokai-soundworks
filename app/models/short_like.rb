class ShortLike < ApplicationRecord
  belongs_to :musician_short
  belongs_to :user

  validates :user_id, uniqueness: { scope: :musician_short_id, message: "has already liked this short" }
end
