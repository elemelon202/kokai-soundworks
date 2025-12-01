class Gig < ApplicationRecord
  belongs_to :venue
  has_many :bookings, dependent: :destroy
  has_many :bands, through: :bookings
  has_many :gig_attendances, dependent: :destroy
  has_many :attendees, through: :gig_attendances, source: :user
  has_many :gig_applications, dependent: :destroy

  has_one_attached :poster


  ATTENDANCE_RATE = 0.05 #5% of followers


  # This gives venue owners:
  # - gig.projected_attendance - estimated attendees based on bands' followers
  # - gig.projected_revenue - estimated ticket sales

  def projected_attendance
    band_ids = bookings.pluck(:band_id)
    follower_count = Follow.where(followable_type: "Band", followable_id: band_ids)
                           .distinct
                           .count(:follower_id)

    [(follower_count * ATTENDANCE_RATE).ceil, venue.capacity || 100].min
  end

  def projected_attendance_by_band
    bookings.includes(:band).map do |booking|
      band = booking.band
      follower_count = band.follows.count
      {
        band: band,
        followers: follower_count,
        projected: (follower_count * ATTENDANCE_RATE).ceil
      }
    end
  end

  def projected_revenue
    ticket_price.to_d * projected_attendance
  end

  def actual_revenue
    ticket_price.to_d * gig_attendances.attended.count
  end
  has_many :gig_attendances
  has_many :attendees, through: :gig_attendances
end
