class Gig < ApplicationRecord
  belongs_to :venue
  has_many :bookings, dependent: :destroy
  has_many :bands, through: :bookings
  has_many :gig_attendances
  has_many :attendees, through: :gig_attendances
end
