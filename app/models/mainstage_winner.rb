# Record of a MAINSTAGE contest winner
# Created when a contest is finalized
# Stores the final scores for historical reference
# Used to display winner badge on musician profiles

class MainstageWinner < ApplicationRecord
  belongs_to :musician
  belongs_to :mainstage_contest

  validates :mainstage_contest_id, uniqueness: true

  scope :recent, -> { order(created_at: :desc) }

  # Get the week label for display (e.g., "Nov 24 - Nov 30, 2025")
  def week_label
    start_date = mainstage_contest.start_date
    end_date = mainstage_contest.end_date
    "#{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}" #LOOOL REMEBER THIS FROM THE START OF THE BOOTCAMP? I DIDNT! -Sam
  end

  # Check if this is the most recent winner (for homepage spotlight)
  def current_spotlight?
    MainstageWinner.recent.first == self
  end
end
