# frozen_string_literal: true

module Stripe
  class PledgeConfirmationService
    def initialize(session_id)
      @session_id = session_id
    end

    def confirm!
      session = ::Stripe::Checkout::Session.retrieve(@session_id)

      pledge = Pledge.find_by(id: session.metadata.pledge_id)
      return { success: false, error: "Pledge not found" } unless pledge

      payment_intent = ::Stripe::PaymentIntent.retrieve(session.payment_intent)

      if payment_intent.status == 'requires_capture'
        pledge.update!(
          status: :authorized,
          authorized_at: Time.current,
          stripe_payment_intent_id: payment_intent.id,
          stripe_payment_method_id: payment_intent.payment_method
        )

        # Check if funding target is now reached
        if pledge.funded_gig.funding_reached?
          # Optionally auto-process, or leave for deadline job
          Rails.logger.info "[FUNDED GIG] Funding target reached for gig #{pledge.funded_gig.id}!"
        end

        { success: true, pledge: pledge }
      else
        pledge.update!(status: :failed)
        { success: false, error: "Payment authorization failed (status: #{payment_intent.status})" }
      end
    rescue ::Stripe::StripeError => e
      Rails.logger.error "[STRIPE PLEDGE] Failed to confirm pledge: #{e.message}"
      { success: false, error: e.message }
    end
  end
end
