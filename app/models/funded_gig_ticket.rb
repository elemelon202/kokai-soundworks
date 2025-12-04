# frozen_string_literal: true

class FundedGigTicket < ApplicationRecord
  belongs_to :funded_gig
  belongs_to :pledge
  belongs_to :user

  enum status: { active: 0, checked_in: 1, cancelled: 2 }

  before_create :generate_ticket_code

  validates :ticket_code, presence: true, uniqueness: true

  scope :usable, -> { where(status: [:active, :checked_in]) }

  def check_in!
    return false unless active?
    update!(status: :checked_in, checked_in_at: Time.current)
  end

  def qr_code_data
    # JSON data for QR code
    {
      ticket_id: id,
      code: ticket_code,
      gig_name: funded_gig.name,
      gig_date: funded_gig.date.iso8601,
      venue: funded_gig.venue.name,
      user_name: display_name
    }.to_json
  end

  def display_name
    pledge.anonymous? ? 'Supporter' : user.username
  end

  def status_badge_class
    case status
    when 'active' then 'success'
    when 'checked_in' then 'primary'
    when 'cancelled' then 'danger'
    else 'secondary'
    end
  end

  private

  def generate_ticket_code
    self.ticket_code = SecureRandom.alphanumeric(12).upcase
  end
end
