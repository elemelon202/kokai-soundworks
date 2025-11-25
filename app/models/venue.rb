class Venue < ApplicationRecord
  belongs_to :user
  has_many :gigs, dependent: :destroy
  has_many_attached :images
end
