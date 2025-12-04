# frozen_string_literal: true

class FundedGig < ApplicationRecord
  belongs_to :gig
  has_one :venue, through: :gig
  has_many :pledges, dependent: :destroy
  has_many :supporters, through: :pledges, source: :user
  has_many :funded_gig_tickets, dependent: :destroy

  # Delegations
  delegate :name, :date, :start_time, :bands, :venue, to: :gig

  PLATFORM_FEE_PERCENT = 5

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

  validates :funding_target_cents, presence: true, numericality: { greater_than: 0 }
  validates :deadline_days_before, numericality: { greater_than_or_equal_to: 3 }
  validate :funding_deadline_before_gig_date

  before_validation :calculate_funding_deadline, on: :create

  scope :active, -> { where(funding_status: [:open_for_applications, :accepting_pledges]) }
  scope :accepting_pledges_now, -> { accepting_pledges.where('funding_deadline > ?', Date.current) }
  scope :needs_processing, -> { accepting_pledges.where('funding_deadline <= ?', Date.current) }
  scope :upcoming, -> { joins(:gig).where('gigs.date >= ?', Date.current).order('gigs.date ASC') }

  # Money helpers
  def funding_target
    funding_target_cents
  end

  def funding_target_yen
    funding_target_cents  # JPY doesn't use decimals
  end

  def current_pledged
    current_pledged_cents
  end

  def current_pledged_yen
    current_pledged_cents
  end

  def funding_percentage
    return 0 if funding_target_cents.zero?
    (current_pledged_cents.to_f / funding_target_cents * 100).round(1)
  end

  def funding_reached?
    current_pledged_cents >= funding_target_cents
  end

  def partial_funding_acceptable?
    allow_partial_funding && funding_percentage >= minimum_funding_percent
  end

  def platform_fee_cents
    (current_pledged_cents * PLATFORM_FEE_PERCENT / 100.0).ceil
  end

  def venue_payout_cents
    current_pledged_cents - platform_fee_cents
  end

  def days_until_deadline
    return 0 unless funding_deadline
    (funding_deadline - Date.current).to_i
  end

  def can_accept_pledges?
    accepting_pledges? && funding_deadline > Date.current
  end

  def can_open_pledges?
    open_for_applications? && gig.bands.any?
  end

  def amount_remaining
    [funding_target_cents - current_pledged_cents, 0].max
  end

  def supporter_count
    pledges.where(status: [:authorized, :captured]).count
  end

  # Status helpers for UI
  def status_badge_class
    case funding_status
    when 'draft' then 'secondary'
    when 'open_for_applications' then 'info'
    when 'accepting_pledges' then 'primary'
    when 'funded', 'partially_funded', 'completed' then 'success'
    when 'failed', 'cancelled' then 'danger'
    else 'secondary'
    end
  end

  def status_label
    case funding_status
    when 'draft' then 'Draft'
    when 'open_for_applications' then 'Accepting Applications'
    when 'accepting_pledges' then 'Accepting Pledges'
    when 'funded' then 'Fully Funded!'
    when 'partially_funded' then 'Partially Funded'
    when 'completed' then 'Completed'
    when 'failed' then 'Funding Failed'
    when 'cancelled' then 'Cancelled'
    else funding_status.humanize
    end
  end

  private

  def calculate_funding_deadline
    return unless gig&.date
    self.funding_deadline = gig.date - deadline_days_before.days
  end

  def funding_deadline_before_gig_date
    return unless gig&.date && funding_deadline
    if funding_deadline >= gig.date
      errors.add(:funding_deadline, "must be before the gig date")
    end
  end
end
