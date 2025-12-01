class Booking < ApplicationRecord
  belongs_to :band
  belongs_to :gig

  after_create_commit :notify_band_followers

  private

  def notify_band_followers
    Notification.create_for_band_gig_announcement(self)
  end
end
