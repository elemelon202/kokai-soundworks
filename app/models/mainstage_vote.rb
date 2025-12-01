# A user's vote for a musician in a MAINSTAGE contest
# Users can only vote once per contest (enforced by DB unique index)
# Each vote is worth 10 points toward the musician's score
# CONTAINS VALIDATIONS SO PEEPS CANT GAME THE SYSTEM

class MainstageVote < ApplicationRecord
  belongs_to :user
  belongs_to :musician
  belongs_to :mainstage_contest

  validates :user_id, uniqueness: {
    scope: :mainstage_contest_id,
    message: "can only vote once per contest"
  }

  # Can't vote for yourself
  validate :cannot_vote_for_self

  # Account must be old enough (same rule as engagement)
  # TEMPORARILY DISABLED FOR PITCH DEMO
  # validate :account_age_requirement

  private

  def cannot_vote_for_self
    return unless user && musician
    if user.musician == musician
      errors.add(:base, "You cannot vote for yourself")
    end
  end

  def account_age_requirement
    return unless user && mainstage_contest
    cutoff = mainstage_contest.start_date - MainstageContest::ACCOUNT_AGE_REQUIREMENT
    if user.created_at > cutoff
      errors.add(:base, "Your account must be at least 3 days old to vote")
    end
  end
end
