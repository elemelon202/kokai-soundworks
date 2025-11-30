class Involvement < ApplicationRecord
  belongs_to :band
  belongs_to :musician

  validates :musician_id, uniqueness: {scope: :band_id, message: "is already in this band"}
  after_create :add_user_to_band_chat
  after_create :auto_follow_band

  private

  def add_user_to_band_chat
    if musician.user && band.chat
      Participation.find_or_create_by(user: musician.user, chat: band.chat)
    end
  end

  # Automatically follow the band when joining
  def auto_follow_band
    return unless musician.user

    unless musician.user.followed_bands.include?(band)
      musician.user.followed_bands << band
    end
  end
end
