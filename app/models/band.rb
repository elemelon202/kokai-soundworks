class Band < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :gigs, through: :bookings
  acts_as_taggable_on :genres

  GENRES = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop', 'Country', 'Electronic', 'Reggae', 'Blues', 'Folk'].freeze

  scope :with_genres, ->(genres) { tagged_with(genres, on: :genres, any: true) }
end
