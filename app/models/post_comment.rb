class PostComment < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
