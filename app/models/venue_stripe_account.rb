# frozen_string_literal: true

class VenueStripeAccount < ApplicationRecord
  belongs_to :venue

  validates :stripe_account_id, presence: true, uniqueness: true

  scope :ready_for_payouts, -> { where(charges_enabled: true, payouts_enabled: true) }

  def onboarding_complete?
    charges_enabled? && payouts_enabled?
  end

  def can_receive_payments?
    account_status == 'active' && onboarding_complete?
  end

  def pending?
    account_status == 'pending'
  end

  def active?
    account_status == 'active'
  end

  def restricted?
    account_status == 'restricted'
  end

  def disabled?
    account_status == 'disabled'
  end
end
