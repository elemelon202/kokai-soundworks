class BandInvitation < ApplicationRecord
  belongs_to :band
  belongs_to :musician
  belongs_to :inviter, class_name: 'User', foreign_key: 'inviter_id'

  validates :musician_id, uniqueness: {scope: :band_id, message: "has already been invited to this band"}

  before_create :generate_token

  private
  def generate_token
    self.token = SecureRandom.hex(20)
  end
end
