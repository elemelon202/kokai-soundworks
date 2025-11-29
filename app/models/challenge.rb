class Challenge < ApplicationRecord
  belongs_to :creator, class_name: 'Musician'
  belongs_to :original_short, class_name: 'MusicianShort'
  belongs_to :winner, class_name: 'ChallengeResponse', optional: true

  has_many :challenge_responses, dependent: :destroy
  has_many :responding_musicians, through: :challenge_responses, source: :musician

  validates :title, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: %w[open voting closed] }

  scope :open, -> { where(status: 'open') }
  scope :voting, -> { where(status: 'voting') }
  scope :closed, -> { where(status: 'closed') }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(responses_count: :desc) }

  # Check if a musician has already responded
  def responded_by?(musician)
    return false unless musician
    challenge_responses.exists?(musician: musician)
  end

  # Get the response from a specific musician
  def response_from(musician)
    challenge_responses.find_by(musician: musician)
  end

  # Start voting phase
  def start_voting!
    update!(status: 'voting')
  end

  # Close challenge and pick winner (highest votes)
  def close_and_pick_winner!
    top_response = challenge_responses.order(votes_count: :desc).first
    update!(status: 'closed', winner: top_response)
  end

  # Manually pick a winner (creator's choice)
  def pick_winner!(response)
    update!(status: 'closed', winner: response)
  end

  def open?
    status == 'open'
  end

  def voting?
    status == 'voting'
  end

  def closed?
    status == 'closed'
  end
end
