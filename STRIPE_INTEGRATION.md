# Stripe Integration Guide for Kokai Soundworks

A comprehensive guide for junior developers on how Stripe is implemented in this crowdfunding platform.

## Table of Contents
1. [Overview](#1-overview)
2. [Configuration](#2-configuration)
3. [Core Models](#3-core-models)
4. [Stripe Services](#4-stripe-services)
5. [Controllers](#5-controllers)
6. [Webhooks](#6-webhooks)
7. [Routes](#7-routes)
8. [Complete Flow Diagrams](#8-complete-flow-diagrams)
9. [Testing Locally](#9-testing-locally)
10. [Common Issues & Debugging](#10-common-issues--debugging)

---

## 1. Overview

This is a **community-funded gig platform** that uses:
- **Stripe Connect** - For venue merchant onboarding (venues receive payouts)
- **Stripe Payment Intents with Manual Capture** - For pledge processing

### The Key Concept: Manual Capture

Unlike normal payments where money is charged immediately, we use **manual capture**:

```
NORMAL PAYMENT:
Customer pays → Money charged immediately

OUR CROWDFUNDING FLOW:
Fan pledges → Payment AUTHORIZED (not charged yet) → Wait for deadline
                                                      ↓
                                            Deadline reached:
                                            - IF funded: CAPTURE (charge customer)
                                            - IF failed: CANCEL (no charge ever)
```

This means fans' cards are validated and funds reserved, but they're only charged if the funding goal is met.

### Money Flow

```
Fan pays ¥5,000
    ↓
Stripe processes payment
    ├── Kokai takes ¥250 (5% platform fee)
    └── Venue receives ¥4,750 (via Stripe Connect transfer)
```

---

## 2. Configuration

### File: `config/initializers/stripe.rb`

```ruby
Stripe.api_key = ENV['STRIPE_API_KEY']
Stripe.api_version = '2024-12-18.acacia'

if Rails.env.development?
  Stripe.log_level = Stripe::LEVEL_INFO
end
```

### Required Environment Variables

```bash
# Your Stripe secret key (starts with sk_test_ or sk_live_)
STRIPE_API_KEY=sk_test_xxxxx

# Webhook signing secret (starts with whsec_)
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
```

**Never commit these to git!** Add them to your `.env` file or Heroku config vars.

---

## 3. Core Models

### A. VenueStripeAccount

Stores Stripe Connect account info for each venue.

**File:** `app/models/venue_stripe_account.rb`

```ruby
class VenueStripeAccount < ApplicationRecord
  belongs_to :venue

  # Key fields:
  # - stripe_account_id: The Stripe account ID (acct_xxxxx)
  # - account_status: pending, active, restricted, disabled
  # - charges_enabled: Can receive payments?
  # - payouts_enabled: Can receive payouts to bank?

  validates :stripe_account_id, presence: true, uniqueness: true

  def onboarding_complete?
    charges_enabled? && payouts_enabled?
  end

  def can_receive_payments?
    account_status == 'active' && onboarding_complete?
  end
end
```

**Status meanings:**
- `pending` - Account created, awaiting Stripe verification
- `active` - Verified and ready for payments
- `restricted` - Has compliance issues to resolve
- `disabled` - Account disabled by Stripe

### B. Pledge

Represents a fan's financial commitment to a funded gig.

**File:** `app/models/pledge.rb`

```ruby
class Pledge < ApplicationRecord
  belongs_to :funded_gig
  belongs_to :user
  has_one :funded_gig_ticket, dependent: :destroy

  # Key fields:
  # - amount_cents: Amount in JPY (e.g., 5000 for ¥5,000)
  # - status: pending, authorized, captured, refunded, failed
  # - stripe_payment_intent_id: Links to Stripe PaymentIntent

  enum status: {
    pending: 0,      # Created, awaiting checkout
    authorized: 1,   # Card charged reserved, not captured
    captured: 2,     # Money actually charged (funding succeeded)
    refunded: 3,     # Cancelled/refunded (funding failed)
    failed: 4        # Payment failed
  }

  # Only one pledge per user per gig
  validates :user_id, uniqueness: { scope: :funded_gig_id }

  scope :successful, -> { where(status: [:authorized, :captured]) }
end
```

**Status lifecycle:**
```
pending → authorized → captured (funding succeeded!)
              ↓
           refunded (funding failed, no charge)
```

### C. FundedGig

The crowdfunding campaign for a gig.

**File:** `app/models/funded_gig.rb`

```ruby
class FundedGig < ApplicationRecord
  belongs_to :gig
  has_many :pledges, dependent: :destroy
  has_many :funded_gig_tickets, dependent: :destroy

  PLATFORM_FEE_PERCENT = 5  # Kokai takes 5%

  # Key fields:
  # - funding_target_cents: Goal amount (e.g., 100000 for ¥100,000)
  # - current_pledged_cents: Sum of successful pledges
  # - funding_status: draft, accepting_pledges, funded, failed, etc.

  enum funding_status: {
    draft: 0,
    open_for_applications: 1,
    accepting_pledges: 2,
    funded: 3,
    failed: 4,
    completed: 5,
    cancelled: 6,
    partially_funded: 7
  }

  def funding_percentage
    (current_pledged_cents.to_f / funding_target_cents * 100).round(1)
  end

  def funding_reached?
    current_pledged_cents >= funding_target_cents
  end

  def platform_fee_cents
    (current_pledged_cents * PLATFORM_FEE_PERCENT / 100.0).ceil
  end

  def venue_payout_cents
    current_pledged_cents - platform_fee_cents
  end
end
```

### D. FundedGigTicket

Free ticket generated when a pledge is captured.

**File:** `app/models/funded_gig_ticket.rb`

```ruby
class FundedGigTicket < ApplicationRecord
  belongs_to :funded_gig
  belongs_to :pledge
  belongs_to :user

  enum status: { active: 0, checked_in: 1, cancelled: 2 }

  before_create :generate_ticket_code

  private

  def generate_ticket_code
    self.ticket_code = SecureRandom.alphanumeric(12).upcase
  end
end
```

---

## 4. Stripe Services

All Stripe business logic lives in `app/services/stripe/`.

### A. ConnectService - Venue Onboarding

**File:** `app/services/stripe/connect_service.rb`

This handles creating Stripe Express accounts for venues.

```ruby
module Stripe
  class ConnectService
    def initialize(venue)
      @venue = venue
    end

    # Step 1: Create a Stripe Express account
    def create_account!
      account = ::Stripe::Account.create(
        type: 'express',           # Express = simpler onboarding
        country: 'JP',             # Japan
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

      # Save the Stripe account ID to our database
      @venue.create_venue_stripe_account!(
        stripe_account_id: account.id,
        account_status: 'pending'
      )

      # Generate the onboarding link
      create_onboarding_link!
    end

    # Step 2: Generate Stripe's hosted onboarding page URL
    def create_onboarding_link!
      link = ::Stripe::AccountLink.create(
        account: @venue.venue_stripe_account.stripe_account_id,
        type: 'account_onboarding',
        refresh_url: refresh_venue_stripe_account_url(@venue),
        return_url: return_venue_stripe_account_url(@venue)
      )

      { success: true, url: link.url }
    end

    # Step 3: After onboarding, refresh the account status
    def refresh_account_status!
      account = ::Stripe::Account.retrieve(
        @venue.venue_stripe_account.stripe_account_id
      )

      @venue.venue_stripe_account.update!(
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        account_status: determine_status(account),
        requirements: account.requirements.to_h
      )
    end

    private

    def determine_status(account)
      return 'disabled' if account.requirements.disabled_reason.present?
      return 'restricted' if account.requirements.currently_due.any?
      return 'active' if account.charges_enabled && account.payouts_enabled
      'pending'
    end
  end
end
```

### B. PledgeCreationService - Starting a Pledge

**File:** `app/services/stripe/pledge_creation_service.rb`

Creates a Stripe Checkout Session with manual capture.

```ruby
module Stripe
  class PledgeCreationService
    def initialize(pledge)
      @pledge = pledge
      @funded_gig = pledge.funded_gig
    end

    def create!
      # Validate the gig can accept pledges
      unless @funded_gig.accepting_pledges?
        return { success: false, error: "This gig is not accepting pledges" }
      end

      # Validate venue is connected to Stripe
      venue_stripe = @funded_gig.venue.venue_stripe_account
      unless venue_stripe&.can_receive_payments?
        return { success: false, error: "Venue is not set up for payments" }
      end

      # Save the pledge first
      return { success: false, error: @pledge.errors.full_messages.join(", ") } unless @pledge.save

      # Create Stripe Checkout Session
      session = ::Stripe::Checkout::Session.create({
        mode: 'payment',

        # CRITICAL: Manual capture - don't charge yet!
        payment_intent_data: {
          capture_method: 'manual',
          metadata: {
            pledge_id: @pledge.id,
            funded_gig_id: @funded_gig.id
          },
          # Send money to venue's Stripe account
          transfer_data: {
            destination: venue_stripe.stripe_account_id
          },
          # Take 5% platform fee
          application_fee_amount: calculate_platform_fee
        },

        line_items: [{
          price_data: {
            currency: 'jpy',
            unit_amount: @pledge.amount_cents,
            product_data: {
              name: "Pledge: #{@funded_gig.name}",
              description: "Support live music at #{@funded_gig.venue.name}"
            }
          },
          quantity: 1
        }],

        customer_email: @pledge.user.email,
        success_url: confirm_funded_gig_pledges_url(@funded_gig) + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: funded_gig_url(@funded_gig)
      })

      { success: true, checkout_url: session.url }
    end

    private

    def calculate_platform_fee
      (@pledge.amount_cents * FundedGig::PLATFORM_FEE_PERCENT / 100.0).ceil
    end
  end
end
```

**Key points:**
- `capture_method: 'manual'` - This is what enables the crowdfunding model
- `transfer_data.destination` - Sends money directly to venue's account
- `application_fee_amount` - Kokai's 5% cut

### C. PledgeConfirmationService - Confirming Authorization

**File:** `app/services/stripe/pledge_confirmation_service.rb`

Called when fan returns from Stripe Checkout.

```ruby
module Stripe
  class PledgeConfirmationService
    def initialize(session_id)
      @session_id = session_id
    end

    def confirm!
      # Get the checkout session from Stripe
      session = ::Stripe::Checkout::Session.retrieve(@session_id)

      # Find our pledge
      pledge = Pledge.find_by(id: session.metadata.pledge_id)
      return { success: false, error: "Pledge not found" } unless pledge

      # Get the PaymentIntent
      payment_intent = ::Stripe::PaymentIntent.retrieve(session.payment_intent)

      # Check if authorization succeeded
      if payment_intent.status == 'requires_capture'
        pledge.update!(
          status: :authorized,
          authorized_at: Time.current,
          stripe_payment_intent_id: payment_intent.id
        )

        { success: true, pledge: pledge }
      else
        pledge.update!(status: :failed)
        { success: false, error: "Payment authorization failed" }
      end
    end
  end
end
```

### D. FundedGigProcessingService - The Main Event!

**File:** `app/services/stripe/funded_gig_processing_service.rb`

This is where the magic happens. Called when the deadline passes.

```ruby
module Stripe
  class FundedGigProcessingService
    def initialize(funded_gig)
      @funded_gig = funded_gig
    end

    def process!
      return { success: false, message: "Already processed" } unless @funded_gig.accepting_pledges?

      if @funded_gig.funding_reached?
        # SUCCESS! Capture all payments
        capture_all_pledges!
        @funded_gig.update!(funding_status: :funded)
        generate_tickets!
        { success: true, message: "Funding complete!" }

      else
        # FAILED - Cancel all payments (no charges)
        refund_all_pledges!
        @funded_gig.update!(funding_status: :failed)
        { success: true, message: "Funding failed. All pledges cancelled." }
      end
    end

    private

    def capture_all_pledges!
      @funded_gig.pledges.authorized.find_each do |pledge|
        begin
          # THIS charges the customer's card
          ::Stripe::PaymentIntent.capture(pledge.stripe_payment_intent_id)
          pledge.update!(status: :captured, captured_at: Time.current)
        rescue ::Stripe::StripeError => e
          Rails.logger.error "Failed to capture pledge #{pledge.id}: #{e.message}"
        end
      end
    end

    def refund_all_pledges!
      @funded_gig.pledges.authorized.find_each do |pledge|
        begin
          # Cancel = no charge ever happened
          ::Stripe::PaymentIntent.cancel(pledge.stripe_payment_intent_id)
          pledge.update!(status: :refunded, refunded_at: Time.current)
        rescue ::Stripe::StripeError => e
          Rails.logger.error "Failed to cancel pledge #{pledge.id}: #{e.message}"
        end
      end
    end

    def generate_tickets!
      @funded_gig.pledges.captured.find_each do |pledge|
        next if pledge.funded_gig_ticket.present?

        pledge.create_funded_gig_ticket!(
          funded_gig: @funded_gig,
          user: pledge.user
        )
      end
    end
  end
end
```

---

## 5. Controllers

### VenueStripeAccountsController

Handles the Stripe Connect onboarding flow.

**File:** `app/controllers/venue_stripe_accounts_controller.rb`

```ruby
class VenueStripeAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_venue

  # GET /venues/:venue_id/stripe_account/new
  # Shows the "Connect with Stripe" button
  def new
  end

  # POST /venues/:venue_id/stripe_account
  # Creates account and redirects to Stripe
  def create
    result = Stripe::ConnectService.new(@venue).create_account!

    if result[:success]
      redirect_to result[:onboarding_url], allow_other_host: true
    else
      redirect_to edit_venue_path(@venue), alert: "Failed to create Stripe account"
    end
  end

  # GET /venues/:venue_id/stripe_account/return
  # Stripe redirects here after onboarding
  def return
    Stripe::ConnectService.new(@venue).refresh_account_status!

    if @venue.stripe_connected?
      redirect_to edit_venue_path(@venue), notice: "Stripe account connected!"
    else
      redirect_to edit_venue_path(@venue), alert: "Please complete Stripe setup"
    end
  end
end
```

### PledgesController

Handles pledge creation and confirmation.

**File:** `app/controllers/pledges_controller.rb`

```ruby
class PledgesController < ApplicationController
  before_action :authenticate_user!

  # GET /funded-gigs/:funded_gig_id/pledges/new
  def new
    @pledge = @funded_gig.pledges.build
  end

  # POST /funded-gigs/:funded_gig_id/pledges
  def create
    @pledge = @funded_gig.pledges.build(pledge_params)
    @pledge.user = current_user

    result = Stripe::PledgeCreationService.new(@pledge).create!

    if result[:success]
      # Redirect to Stripe Checkout
      redirect_to result[:checkout_url], allow_other_host: true
    else
      flash.now[:alert] = result[:error]
      render :new, status: :unprocessable_entity
    end
  end

  # GET /funded-gigs/:funded_gig_id/pledges/confirm?session_id=xxx
  def confirm
    result = Stripe::PledgeConfirmationService.new(params[:session_id]).confirm!

    if result[:success]
      redirect_to funded_gig_path(@funded_gig), notice: "Thank you for your pledge!"
    else
      redirect_to funded_gig_path(@funded_gig), alert: result[:error]
    end
  end
end
```

---

## 6. Webhooks

Stripe sends events to your app when things happen (payments authorized, captured, etc.).

**File:** `app/controllers/webhooks/stripe_controller.rb`

```ruby
module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token  # Stripe can't send CSRF token
    skip_before_action :authenticate_user!          # No user session

    def receive
      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']

      begin
        # ALWAYS verify the webhook signature!
        event = Stripe::Webhook.construct_event(
          payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
        )
      rescue Stripe::SignatureVerificationError
        return render json: { error: 'Invalid signature' }, status: :bad_request
      end

      # Handle different event types
      case event.type
      when 'payment_intent.amount_capturable_updated'
        handle_payment_authorized(event.data.object)

      when 'payment_intent.succeeded'
        handle_payment_captured(event.data.object)

      when 'payment_intent.canceled'
        handle_payment_cancelled(event.data.object)

      when 'account.updated'
        handle_account_updated(event.data.object)
      end

      render json: { received: true }
    end

    private

    def handle_payment_authorized(payment_intent)
      pledge = Pledge.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless pledge

      pledge.update!(status: :authorized) if pledge.pending?
    end

    def handle_payment_captured(payment_intent)
      pledge = Pledge.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless pledge

      pledge.update!(status: :captured, captured_at: Time.current) if pledge.authorized?
    end

    def handle_payment_cancelled(payment_intent)
      pledge = Pledge.find_by(stripe_payment_intent_id: payment_intent.id)
      return unless pledge

      pledge.update!(status: :refunded, refunded_at: Time.current) unless pledge.refunded?
    end

    def handle_account_updated(account)
      venue_stripe = VenueStripeAccount.find_by(stripe_account_id: account.id)
      return unless venue_stripe

      Stripe::ConnectService.new(venue_stripe.venue).refresh_account_status!
    end
  end
end
```

### Setting Up Webhooks in Stripe Dashboard

1. Go to **Developers → Webhooks** in Stripe Dashboard
2. Click **Add endpoint**
3. Enter your URL: `https://yourdomain.com/webhooks/stripe`
4. Select these events:
   - `payment_intent.amount_capturable_updated`
   - `payment_intent.succeeded`
   - `payment_intent.canceled`
   - `account.updated`
   - `checkout.session.completed`
5. Copy the signing secret to `STRIPE_WEBHOOK_SECRET`

---

## 7. Routes

**File:** `config/routes.rb`

```ruby
Rails.application.routes.draw do
  # Stripe Connect for venues
  resources :venues do
    resource :stripe_account, controller: 'venue_stripe_accounts', only: [:new, :create] do
      get :onboarding
      get :return
      get :refresh
    end
  end

  # Funded gigs and pledges
  resources :funded_gigs, path: 'funded-gigs' do
    member do
      patch :process_funding
    end

    resources :pledges, only: [:new, :create, :show] do
      collection do
        get :confirm
      end
      member do
        delete :cancel
      end
    end
  end

  # Stripe webhooks
  namespace :webhooks do
    post 'stripe', to: 'stripe#receive'
  end
end
```

---

## 8. Complete Flow Diagrams

### Venue Stripe Connect Onboarding

```
1. Venue owner visits their venue edit page
2. Clicks "Connect with Stripe"
   ↓
3. VenueStripeAccountsController#create
   ↓
4. Stripe::ConnectService.create_account!
   - Creates Stripe Express account
   - Saves stripe_account_id to database
   - Generates onboarding link
   ↓
5. Redirect to Stripe.com (allow_other_host: true)
   ↓
6. Venue fills out business info, bank details on Stripe
   ↓
7. Stripe redirects to return_url
   ↓
8. VenueStripeAccountsController#return
   ↓
9. Stripe::ConnectService.refresh_account_status!
   - Updates charges_enabled, payouts_enabled
   ↓
10. Venue is connected! ✓
```

### Fan Pledge Flow

```
1. Fan visits funded gig page, clicks "Pledge Now"
   ↓
2. PledgesController#new - Shows pledge form
   ↓
3. Fan enters amount (¥5,000), submits
   ↓
4. PledgesController#create
   ↓
5. Stripe::PledgeCreationService.create!
   - Creates Pledge (status: pending)
   - Creates Stripe Checkout Session with manual capture
   ↓
6. Redirect to Stripe Checkout
   ↓
7. Fan enters card details on Stripe
   ↓
8. Stripe authorizes payment (NOT charged yet)
   - PaymentIntent status: requires_capture
   ↓
9. Stripe redirects to confirm URL
   ↓
10. PledgesController#confirm
    ↓
11. Stripe::PledgeConfirmationService.confirm!
    - Updates Pledge status: authorized
    - Saves stripe_payment_intent_id
    ↓
12. "Thank you!" - Fan sees success message

[Money is reserved on card but NOT charged]
```

### Funding Processing (at deadline)

```
1. Deadline passes OR venue clicks "Process Funding"
   ↓
2. FundedGigsController#process_funding
   ↓
3. Stripe::FundedGigProcessingService.process!
   ↓
   ├── IF funding_reached? (>= 100%)
   │   ↓
   │   capture_all_pledges!
   │   - For each authorized pledge:
   │     Stripe::PaymentIntent.capture(payment_intent_id)
   │   - Update pledge status: captured
   │   - NOW the fan's card is charged!
   │   ↓
   │   generate_tickets!
   │   - Create FundedGigTicket for each backer
   │   ↓
   │   Update funded_gig status: funded
   │   ↓
   │   SUCCESS! Fans get tickets, venue gets paid
   │
   └── ELSE (funding failed)
       ↓
       refund_all_pledges!
       - For each authorized pledge:
         Stripe::PaymentIntent.cancel(payment_intent_id)
       - Update pledge status: refunded
       - Fan's card is NEVER charged
       ↓
       Update funded_gig status: failed
       ↓
       FAILED - No one is charged, no tickets
```

---

## 9. Testing Locally

### Test Mode Credentials

Use Stripe test mode (keys start with `sk_test_` and `pk_test_`):

```bash
# .env file
STRIPE_API_KEY=sk_test_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_test_xxxxx
```

### Test Card Numbers

| Card Number | Result |
|-------------|--------|
| 4242 4242 4242 4242 | Success |
| 4000 0000 0000 0002 | Declined |
| 4000 0000 0000 3220 | Requires authentication |

Use any future expiry date (e.g., 12/34) and any 3-digit CVC.

### Testing Webhooks Locally

Use Stripe CLI to forward webhooks to localhost:

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to your local server
stripe listen --forward-to localhost:3000/webhooks/stripe

# This will give you a webhook signing secret (whsec_xxx)
# Use this as STRIPE_WEBHOOK_SECRET for local testing
```

---

## 10. Common Issues & Debugging

### "Venue not connected to Stripe"

Check in Rails console:
```ruby
venue = Venue.find(id)
venue.venue_stripe_account          # Should exist
venue.venue_stripe_account.charges_enabled  # Should be true
venue.venue_stripe_account.payouts_enabled  # Should be true
venue.stripe_connected?             # Should return true
```

### Pledge stuck in "pending"

The pledge didn't get the PaymentIntent ID from Stripe:
```ruby
pledge = Pledge.find(id)
pledge.stripe_payment_intent_id  # Should NOT be nil

# If nil, check webhook logs in Stripe Dashboard
```

### Funds not captured after processing

Check if the processing service ran:
```ruby
funded_gig = FundedGig.find(id)
funded_gig.pledges.captured.count  # Should be > 0 if successful

# Check logs for errors
```

### Webhook signature invalid

Make sure:
1. `STRIPE_WEBHOOK_SECRET` is set correctly
2. You're using the right secret for the environment (test vs live)
3. The request body isn't being modified by middleware

---

## Files Quick Reference

| File | Purpose |
|------|---------|
| `config/initializers/stripe.rb` | Stripe configuration |
| `app/models/venue_stripe_account.rb` | Stripe Connect account |
| `app/models/pledge.rb` | Pledge/payment record |
| `app/models/funded_gig.rb` | Crowdfunding campaign |
| `app/models/funded_gig_ticket.rb` | Generated ticket |
| `app/services/stripe/connect_service.rb` | Venue onboarding |
| `app/services/stripe/pledge_creation_service.rb` | Create pledge payment |
| `app/services/stripe/pledge_confirmation_service.rb` | Confirm authorization |
| `app/services/stripe/funded_gig_processing_service.rb` | Capture/refund logic |
| `app/controllers/venue_stripe_accounts_controller.rb` | Onboarding flow |
| `app/controllers/pledges_controller.rb` | Pledge creation |
| `app/controllers/webhooks/stripe_controller.rb` | Webhook handler |

---

## Need Help?

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Connect Guide](https://stripe.com/docs/connect)
- [Payment Intents API](https://stripe.com/docs/payments/payment-intents)
- [Webhook Guide](https://stripe.com/docs/webhooks)
