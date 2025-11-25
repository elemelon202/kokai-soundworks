class Involvement < ApplicationRecord
  belongs_to :band
  belongs_to :musician

  validates :musician_id, uniqueness: {scope: :band_id, message: "is already in this band"}
  after_create :add_user_to_band_chat

  private

  def add_user_to_band_chat
    if musician.user && band.chat
      Participation.find_or_create_by(user: musician.user, chat: band.chat)
    end
  end
end
