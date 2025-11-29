# Record of a BAND MAINSTAGE contest winner
# Created when a contest is finalized
# Stores the final scores for historical reference

class BandMainstageWinner < ApplicationRecord
  belongs_to :band
  belongs_to :band_mainstage_contest

  validates :band_mainstage_contest_id, uniqueness: true

  scope :recent, -> { order(created_at: :desc) }

  def week_label
    start_date = band_mainstage_contest.start_date
    end_date = band_mainstage_contest.end_date
    "#{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}"
  end

  def current_spotlight?
    BandMainstageWinner.recent.first == self
  end
end
