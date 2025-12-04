# frozen_string_literal: true

module Stripe
  class ConnectService
    def initialize(venue)
      @venue = venue
    end

    def create_account!
      account = ::Stripe::Account.create(
        type: 'express',
        country: 'JP',
        email: @venue.user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        business_type: 'company',
        metadata: {
          venue_id: @venue.id,
          venue_name: @venue.name
        }
      )

      @venue.create_venue_stripe_account!(
        stripe_account_id: account.id,
        account_status: 'pending'
      )

      onboarding_result = create_onboarding_link!
      return onboarding_result unless onboarding_result[:success]

      { success: true, onboarding_url: onboarding_result[:url] }
    rescue ::Stripe::StripeError => e
      Rails.logger.error "[STRIPE CONNECT] Failed to create account: #{e.message}"
      { success: false, error: e.message }
    end

    def create_onboarding_link!
      return { success: false, error: "No Stripe account" } unless @venue.venue_stripe_account

      link = ::Stripe::AccountLink.create(
        account: @venue.venue_stripe_account.stripe_account_id,
        refresh_url: Rails.application.routes.url_helpers.refresh_venue_stripe_account_url(@venue, host: default_host),
        return_url: Rails.application.routes.url_helpers.return_venue_stripe_account_url(@venue, host: default_host),
        type: 'account_onboarding'
      )

      { success: true, url: link.url }
    rescue ::Stripe::StripeError => e
      Rails.logger.error "[STRIPE CONNECT] Failed to create onboarding link: #{e.message}"
      { success: false, error: e.message }
    end

    def refresh_account_status!
      return unless @venue.venue_stripe_account

      account = ::Stripe::Account.retrieve(@venue.venue_stripe_account.stripe_account_id)

      @venue.venue_stripe_account.update!(
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        account_status: determine_status(account),
        requirements: account.requirements.to_h,
        onboarded_at: account.charges_enabled ? Time.current : nil
      )

      { success: true }
    rescue ::Stripe::StripeError => e
      Rails.logger.error "[STRIPE CONNECT] Failed to refresh account status: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def determine_status(account)
      return 'disabled' if account.requirements.disabled_reason.present?
      return 'restricted' if account.requirements.currently_due.any?
      return 'active' if account.charges_enabled && account.payouts_enabled
      'pending'
    end

    def default_host
      Rails.env.production? ? 'kokai-soundworks-e3e70015f20a.herokuapp.com' : 'localhost:3000'
    end
  end
end
