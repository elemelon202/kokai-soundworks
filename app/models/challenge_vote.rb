class ChallengeVote < ApplicationRecord
  belongs_to :user
  belongs_to :challenge_response, counter_cache: :votes_count

  validates :user_id, uniqueness: { scope: :challenge_response_id, message: "has already voted for this response" }
  validate :challenge_must_be_in_voting_or_open
  validate :cannot_vote_for_own_response

  private

  def challenge_must_be_in_voting_or_open
    if challenge_response&.challenge&.closed?
      errors.add(:base, "This challenge is closed for voting")
    end
  end

  def cannot_vote_for_own_response
    if user&.musician && challenge_response&.musician == user.musician
      errors.add(:base, "You cannot vote for your own response")
    end
  end
end
