class Gig < ApplicationRecord
  belongs_to :venue
  has_many :bookings, dependent: :destroy
  has_many :bands, through: :bookings
end
