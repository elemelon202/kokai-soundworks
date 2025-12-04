# frozen_string_literal: true

class Pledge < ApplicationRecord
  belongs_to :funded_gig
  belongs_to :user
  has_one :funded_gig_ticket, dependent: :destroy

  enum status: {
    pending: 0,
    authorized: 1,
    captured: 2,
    refunded: 3,
    failed: 4
  }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :funded_gig_id, message: "has already pledged to this gig" }

  scope :successful, -> { where(status: [:authorized, :captured]) }
  scope :needs_capture, -> { authorized }
  scope :needs_refund, -> { authorized }

  after_save :update_funded_gig_total, if: :saved_change_to_status?
  after_create :update_funded_gig_total

  # Money helpers
  def amount
    amount_cents
  end

  def amount_yen
    amount_cents  # JPY doesn't use decimals
  end

  def refundable?
    authorized? || captured?
  end

  def display_name
    anonymous? ? 'Anonymous Supporter' : user.username
  end

  def status_badge_class
    case status
    when 'pending' then 'warning'
    when 'authorized' then 'info'
    when 'captured' then 'success'
    when 'refunded' then 'secondary'
    when 'failed' then 'danger'
    else 'secondary'
    end
  end

  private

  def update_funded_gig_total
    total = funded_gig.pledges.successful.sum(:amount_cents)
    funded_gig.update_column(:current_pledged_cents, total)
    broadcast_funding_update
  end

  def broadcast_funding_update
    funded_gig.reload
    ActionCable.server.broadcast(
      "funded_gig_#{funded_gig.id}",
      {
        type: 'funding_update',
        current_pledged_cents: funded_gig.current_pledged_cents,
        funding_target_cents: funded_gig.funding_target_cents,
        funding_percentage: funded_gig.funding_percentage,
        supporter_count: funded_gig.supporter_count,
        funding_reached: funded_gig.funding_reached?,
        latest_pledge: {
          amount: amount_cents,
          display_name: display_name
        }
      }
    )
  end
end
