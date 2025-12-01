# A user's vote for a band in a BAND MAINSTAGE contest
# Users can only vote once per contest (enforced by DB unique index)
# Each vote is worth 10 points toward the band's score

class BandMainstageVote < ApplicationRecord
  belongs_to :user
  belongs_to :band
  belongs_to :band_mainstage_contest

  validates :user_id, uniqueness: {
    scope: :band_mainstage_contest_id,
    message: "can only vote once per contest"
  }

  # Can't vote for your own band
  validate :cannot_vote_for_own_band

  # Account must be old enough
  # TEMPORARILY DISABLED FOR PITCH DEMO
  # validate :account_age_requirement

  private

  def cannot_vote_for_own_band
    return unless user && band
    if band.musicians.any? { |m| m.user == user }
      errors.add(:base, "You cannot vote for your own band")
    end
  end

  def account_age_requirement
    return unless user && band_mainstage_contest
    cutoff = band_mainstage_contest.start_date - BandMainstageContest::ACCOUNT_AGE_REQUIREMENT
    if user.created_at > cutoff
      errors.add(:base, "Your account must be at least 3 days old to vote")
    end
  end
end
