class GigApplication < ApplicationRecord
  belongs_to :gig
  belongs_to :band

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :band_id, uniqueness: { scope: :gig_id, message: "has already applied to this gig" }

  before_create :capture_band_metrics

  private

  # Capture band's Mainstage score and follower count at time of application
  # This provides a snapshot for venue owners to evaluate applications
  def capture_band_metrics
    return unless gig.funded?

    # Get current Mainstage score
    contest = BandMainstageContest.current_contest
    if contest
      leaderboard_entry = contest.leaderboard(100).find { |e| e[:band].id == band_id }
      self.mainstage_score_at_application = leaderboard_entry&.dig(:total_score) || 0
    end

    # Capture follower count
    self.follower_count_at_application = band.follows.count

    # Count past gigs
    self.past_gig_count = band.gigs.where('date < ?', Date.current).count
  end
end
