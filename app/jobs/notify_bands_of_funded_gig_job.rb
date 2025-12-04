# frozen_string_literal: true

class NotifyBandsOfFundedGigJob < ApplicationJob
  queue_as :default

  def perform(funded_gig_id)
    funded_gig = FundedGig.find(funded_gig_id)
    venue = funded_gig.venue

    notified_user_ids = Set.new

    # Notify bands in the same city/area
    Band.where(location: venue.city).find_each do |band|
      band.musicians.each do |musician|
        next unless musician.user
        next if notified_user_ids.include?(musician.user.id)

        create_notification(funded_gig, musician.user)
        notified_user_ids << musician.user.id
      end
    end

    # Also notify top Mainstage bands
    contest = BandMainstageContest.current_contest
    if contest
      contest.leaderboard(30).each do |entry|
        band = entry[:band]
        band.musicians.each do |musician|
          next unless musician.user
          next if notified_user_ids.include?(musician.user.id)

          create_notification(funded_gig, musician.user)
          notified_user_ids << musician.user.id
        end
      end
    end

    Rails.logger.info "[NOTIFY BANDS] Notified #{notified_user_ids.size} users about funded gig #{funded_gig_id}"
  end

  private

  def create_notification(funded_gig, user)
    Notification.create(
      user: user,
      notification_type: 'funded_gig_opportunity',
      notifiable: funded_gig,
      message: "New funded gig opportunity: #{funded_gig.name} at #{funded_gig.venue.name}! Apply now - venue selects bands by Mainstage score.",
      read: false
    )
  end
end
