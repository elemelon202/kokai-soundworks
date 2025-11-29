class ChallengeResponse < ApplicationRecord
  belongs_to :challenge, counter_cache: :responses_count
  belongs_to :musician_short, class_name: 'MusicianShort'
  belongs_to :musician

  has_many :challenge_votes, dependent: :destroy
  has_many :voters, through: :challenge_votes, source: :user

  validates :musician_id, uniqueness: { scope: :challenge_id, message: "has already responded to this challenge" }
  validate :cannot_respond_to_own_challenge

  scope :top_voted, -> { order(votes_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # Check if user has voted for this response
  def voted_by?(user)
    return false unless user
    challenge_votes.exists?(user: user)
  end

  private

  def cannot_respond_to_own_challenge
    if challenge && musician == challenge.creator
      errors.add(:base, "You cannot respond to your own challenge")
    end
  end
end
