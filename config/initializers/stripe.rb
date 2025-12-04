# frozen_string_literal: true

Stripe.api_key = ENV['STRIPE_API_KEY']

# Configure Stripe API version
Stripe.api_version = '2024-12-18.acacia'

# Enable logging in development
if Rails.env.development?
  Stripe.log_level = Stripe::LEVEL_INFO
end
