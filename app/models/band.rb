class Band < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :gigs, through: :bookings
  has_many :musicians, through: :involvements
  has_many :involvements, dependent: :destroy
end
