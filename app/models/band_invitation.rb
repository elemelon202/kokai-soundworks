class BandInvitation < ApplicationRecord
  belongs_to :band
  belongs_to :musician
  belongs_to :inviter, class_name: 'User', foreign_key: 'inviter_id'

  validates :musician_id, uniqueness: {
    scope: :band_id,
    conditions: -> { pending },
    message: "has a pending invitation to this band"
  }

  before_create :generate_token

  scope :pending, -> { where(status: 'Pending') }
  scope :accepted, -> { where(status: 'Accepted') }
  scope :declined, -> { where(status: 'Declined') }
  scope :sent_by, ->(user) { where(inviter: user) }

  private
  def generate_token
    self.token = SecureRandom.hex(20)
  end
end
