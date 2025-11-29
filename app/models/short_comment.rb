class ShortComment < ApplicationRecord
  belongs_to :musician_short
  belongs_to :user

  validates :body, presence: true, length: { maximum: 500 }

  default_scope { order(created_at: :desc) }
end
