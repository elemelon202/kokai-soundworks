# frozen_string_literal: true

module Stripe
  class PledgeCreationService
    def initialize(pledge)
      @pledge = pledge
      @funded_gig = pledge.funded_gig
    end

    def create!
      return { success: false, error: "Gig not accepting pledges" } unless @funded_gig.can_accept_pledges?

      venue_stripe_account = @funded_gig.venue.venue_stripe_account
      return { success: false, error: "Venue not connected to Stripe" } unless venue_stripe_account&.can_receive_payments?

      # Save the pledge first to get an ID
      unless @pledge.save
        return { success: false, error: @pledge.errors.full_messages.join(", ") }
      end

      # Create Checkout Session with manual capture
      session = ::Stripe::Checkout::Session.create({
        mode: 'payment',
        payment_intent_data: {
          capture_method: 'manual',  # Authorize but don't capture yet
          metadata: {
            pledge_id: @pledge.id,
            funded_gig_id: @funded_gig.id,
            user_id: @pledge.user_id
          },
          transfer_data: {
            destination: venue_stripe_account.stripe_account_id
          },
          application_fee_amount: calculate_platform_fee
        },
        line_items: [{
          price_data: {
            currency: @pledge.currency,
            unit_amount: @pledge.amount_cents,
            product_data: {
              name: "Pledge: #{@funded_gig.name}",
              description: "Support live music at #{@funded_gig.venue.name} on #{@funded_gig.date.strftime('%B %d, %Y')}"
            }
          },
          quantity: 1
        }],
        customer_email: @pledge.user.email,
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: {
          pledge_id: @pledge.id,
          funded_gig_id: @funded_gig.id
        }
      })

      { success: true, checkout_url: session.url, session_id: session.id }
    rescue ::Stripe::StripeError => e
      Rails.logger.error "[STRIPE PLEDGE] Failed to create checkout session: #{e.message}"
      @pledge.update(status: :failed)
      { success: false, error: e.message }
    end

    private

    def calculate_platform_fee
      (@pledge.amount_cents * FundedGig::PLATFORM_FEE_PERCENT / 100.0).ceil
    end

    def success_url
      Rails.application.routes.url_helpers.confirm_funded_gig_pledges_url(
        @funded_gig,
        host: default_host
      ) + "?session_id={CHECKOUT_SESSION_ID}"
    end

    def cancel_url
      Rails.application.routes.url_helpers.funded_gig_url(@funded_gig, host: default_host)
    end

    def default_host
      Rails.env.production? ? 'kokai-soundworks-e3e70015f20a.herokuapp.com' : 'localhost:3000'
    end
  end
end
