# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!

    def receive
      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError => e
        Rails.logger.error "[STRIPE WEBHOOK] Invalid payload: #{e.message}"
        render json: { error: 'Invalid payload' }, status: :bad_request
        return
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error "[STRIPE WEBHOOK] Invalid signature: #{e.message}"
        render json: { error: 'Invalid signature' }, status: :bad_request
        return
      end

      Rails.logger.info "[STRIPE WEBHOOK] Received event: #{event.type}"

      case event.type
      when 'payment_intent.amount_capturable_updated'
        handle_payment_capturable(event.data.object)
      when 'payment_intent.succeeded'
        handle_payment_succeeded(event.data.object)
      when 'payment_intent.canceled'
        handle_payment_canceled(event.data.object)
      when 'account.updated'
        handle_account_updated(event.data.object)
      when 'checkout.session.completed'
        handle_checkout_completed(event.data.object)
      end

      render json: { received: true }
    end

    private

    def handle_payment_capturable(payment_intent)
      pledge = Pledge.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless pledge

      if pledge.pending?
        pledge.update!(status: :authorized, authorized_at: Time.current)
        Rails.logger.info "[STRIPE WEBHOOK] Pledge #{pledge.id} authorized"
      end
    end

    def handle_payment_succeeded(payment_intent)
      pledge = Pledge.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless pledge

      if payment_intent.amount_received > 0 && pledge.authorized?
        pledge.update!(status: :captured, captured_at: Time.current)
        Rails.logger.info "[STRIPE WEBHOOK] Pledge #{pledge.id} captured"
      end
    end

    def handle_payment_canceled(payment_intent)
      pledge = Pledge.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless pledge

      unless pledge.refunded?
        pledge.update!(status: :refunded, refunded_at: Time.current)
        Rails.logger.info "[STRIPE WEBHOOK] Pledge #{pledge.id} refunded/cancelled"
      end
    end

    def handle_account_updated(account)
      venue_stripe_account = VenueStripeAccount.find_by(stripe_account_id: account.id)
      return unless venue_stripe_account

      Stripe::ConnectService.new(venue_stripe_account.venue).refresh_account_status!
      Rails.logger.info "[STRIPE WEBHOOK] Venue account #{account.id} status refreshed"
    end

    def handle_checkout_completed(session)
      pledge_id = session.metadata&.pledge_id
      return unless pledge_id

      pledge = Pledge.find_by(id: pledge_id)
      return unless pledge

      if session.payment_intent && pledge.pending?
        pledge.update!(stripe_payment_intent_id: session.payment_intent)
        Rails.logger.info "[STRIPE WEBHOOK] Pledge #{pledge.id} linked to payment intent"
      end
    end
  end
end
