# frozen_string_literal: true

module Stripe
  class FundedGigProcessingService
    def initialize(funded_gig)
      @funded_gig = funded_gig
    end

    def process!(accept_partial: false)
      return { success: false, message: "Already processed" } unless @funded_gig.accepting_pledges?

      if @funded_gig.funding_reached?
        capture_all_pledges!
        @funded_gig.update!(funding_status: :funded, funded_at: Time.current)
        generate_tickets!
        notify_success!
        { success: true, message: "Funding complete! All pledges captured." }

      elsif accept_partial && @funded_gig.partial_funding_acceptable?
        capture_all_pledges!
        @funded_gig.update!(funding_status: :partially_funded, funded_at: Time.current)
        generate_tickets!
        notify_partial_success!
        { success: true, message: "Partial funding accepted. Pledges captured." }

      else
        refund_all_pledges!
        @funded_gig.update!(funding_status: :failed, failed_at: Time.current)
        notify_failure!
        { success: true, message: "Funding target not reached. All pledges refunded." }
      end
    rescue StandardError => e
      Rails.logger.error "[FUNDED GIG PROCESSING] Error: #{e.message}"
      { success: false, message: e.message }
    end

    private

    def capture_all_pledges!
      @funded_gig.pledges.authorized.find_each do |pledge|
        begin
          ::Stripe::PaymentIntent.capture(pledge.stripe_payment_intent_id)
          pledge.update!(status: :captured, captured_at: Time.current)
          Rails.logger.info "[FUNDED GIG] Captured pledge #{pledge.id} for #{pledge.amount_cents} cents"
        rescue ::Stripe::StripeError => e
          Rails.logger.error "[FUNDED GIG] Failed to capture pledge #{pledge.id}: #{e.message}"
        end
      end
    end

    def refund_all_pledges!
      @funded_gig.pledges.authorized.find_each do |pledge|
        begin
          ::Stripe::PaymentIntent.cancel(pledge.stripe_payment_intent_id)
          pledge.update!(status: :refunded, refunded_at: Time.current, refund_reason: 'funding_failed')
          Rails.logger.info "[FUNDED GIG] Cancelled/refunded pledge #{pledge.id}"
        rescue ::Stripe::StripeError => e
          Rails.logger.error "[FUNDED GIG] Failed to refund pledge #{pledge.id}: #{e.message}"
        end
      end
    end

    def generate_tickets!
      @funded_gig.pledges.captured.find_each do |pledge|
        next if pledge.funded_gig_ticket.present?  # Don't duplicate

        pledge.create_funded_gig_ticket!(
          funded_gig: @funded_gig,
          user: pledge.user
        )
        Rails.logger.info "[FUNDED GIG] Generated ticket for pledge #{pledge.id}"
      end
    end

    def notify_success!
      # Notify all supporters
      @funded_gig.supporters.find_each do |user|
        Notification.create(
          user: user,
          notification_type: 'funded_gig_success',
          notifiable: @funded_gig,
          message: "Great news! #{@funded_gig.name} is fully funded! Your free ticket is ready.",
          read: false
        )
      end

      # Notify bands
      @funded_gig.gig.bands.each do |band|
        band.musicians.each do |musician|
          next unless musician.user
          Notification.create(
            user: musician.user,
            notification_type: 'funded_gig_band_confirmed',
            notifiable: @funded_gig,
            message: "#{band.name} is confirmed to play at #{@funded_gig.name}! The community funded the show.",
            read: false
          )
        end
      end

      # Notify venue owner
      Notification.create(
        user: @funded_gig.venue.user,
        notification_type: 'funded_gig_venue_success',
        notifiable: @funded_gig,
        message: "#{@funded_gig.name} is fully funded! You'll receive ¥#{@funded_gig.venue_payout_cents.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}.",
        read: false
      )

      # LINE bot announcements
      announce_to_line_groups!
    end

    def notify_partial_success!
      notify_success!  # Same notifications, different status tracked in DB
    end

    def notify_failure!
      @funded_gig.supporters.find_each do |user|
        Notification.create(
          user: user,
          notification_type: 'funded_gig_failed',
          notifiable: @funded_gig,
          message: "Unfortunately, #{@funded_gig.name} didn't reach its funding goal. Your pledge has been cancelled - you won't be charged.",
          read: false
        )
      end

      # Notify venue owner
      Notification.create(
        user: @funded_gig.venue.user,
        notification_type: 'funded_gig_venue_failed',
        notifiable: @funded_gig,
        message: "#{@funded_gig.name} didn't reach its funding goal. All pledges have been refunded.",
        read: false
      )
    end

    def announce_to_line_groups!
      @funded_gig.gig.bands.each do |band|
        band.line_band_connections.where(active: true).each do |connection|
          message = "🎉 #{@funded_gig.name} is FUNDED!\n\n" \
                    "#{@funded_gig.supporter_count} supporters backed this show!\n" \
                    "📅 #{@funded_gig.date.strftime('%B %d, %Y')}\n" \
                    "📍 #{@funded_gig.venue.name}"

          begin
            client = Line::Bot::Client.new do |config|
              config.channel_secret = ENV['LINE_CHANNEL_SECRET']
              config.channel_token = ENV['LINE_CHANNEL_TOKEN']
            end
            client.push_message(connection.line_group_id, { type: 'text', text: message })
          rescue StandardError => e
            Rails.logger.error "[LINE] Failed to announce funded gig: #{e.message}"
          end
        end
      end
    end
  end
end
