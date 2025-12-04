# frozen_string_literal: true

class NotifyFansOfFundedGigJob < ApplicationJob
  queue_as :default

  def perform(funded_gig_id)
    funded_gig = FundedGig.find(funded_gig_id)

    # Get all followers of the playing bands
    band_ids = funded_gig.gig.band_ids
    follower_ids = Follow.where(followable_type: 'Band', followable_id: band_ids)
                         .pluck(:follower_id)
                         .uniq

    notified_count = 0

    User.where(id: follower_ids).find_each do |user|
      Notification.create(
        user: user,
        notification_type: 'funded_gig_pledging_open',
        notifiable: funded_gig,
        message: "Your favorite bands are playing #{funded_gig.name}! Pledge now to get a free ticket when the show is funded.",
        read: false
      )
      notified_count += 1
    end

    # LINE bot announcements to band groups
    funded_gig.gig.bands.each do |band|
      announce_to_line_group(band, funded_gig)
    end

    Rails.logger.info "[NOTIFY FANS] Notified #{notified_count} fans about pledging for funded gig #{funded_gig_id}"
  end

  private

  def announce_to_line_group(band, funded_gig)
    band.line_band_connections.where(active: true).each do |connection|
      message = "🎸 #{funded_gig.name} is now accepting pledges!\n\n" \
                "#{band.name} is playing - help fund the show!\n" \
                "🎯 Goal: ¥#{funded_gig.funding_target_yen.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}\n" \
                "📅 #{funded_gig.date.strftime('%B %d, %Y')}\n" \
                "📍 #{funded_gig.venue.name}\n\n" \
                "Pledge now → Fans get FREE tickets if funded!"

      begin
        client = Line::Bot::Client.new do |config|
          config.channel_secret = ENV['LINE_CHANNEL_SECRET']
          config.channel_token = ENV['LINE_CHANNEL_TOKEN']
        end
        client.push_message(connection.line_group_id, { type: 'text', text: message })
      rescue StandardError => e
        Rails.logger.error "[LINE] Failed to announce pledging: #{e.message}"
      end
    end
  end
end
