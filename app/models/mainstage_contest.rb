# Represents a weekly MAINSTAGE contest period
# Each contest runs Sunday to Saturday
# Winners are determined by engagement score + community votes
#
# Anti-gaming protections:
# - Account must be 3+ days old for engagement to count
# - Max 15 points any single user can contribute to a musician
# - THIS IS THE WOW FACTOR TO KEEP BANDS AND MUSICIANS ON THE SITE. IT COMBINES ALL THE ENGAGEMENT THINGS LIKE CHAT, SHORTS, POSTS, BLAH BLAH BLAH. IT ALSO DEMONSTRATES THAT THEY AS AN ARTIST CAN DEVELOP A FOLLOWING. ITS THE FIRST THING BOOKING AGENTS LOOK FOR, AND WITH THIS THEY HAVE A COMPACT EASY TO SHOWCASE PROOF THAT THEY CAN ENTERTAIN!!!!
class MainstageContest < ApplicationRecord
  ACCOUNT_AGE_REQUIREMENT = 3.days
  MAX_POINTS_PER_USER = 15
  has_many :mainstage_votes, dependent: :destroy
  has_one :mainstage_winner, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :current, -> { active.where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }

  STATUSES = %w[active completed].freeze

  # Get or create the current week's contest
  def self.current_contest
    current.first || create_current_week_contest
  end

  # Create a contest for the current week (Sunday to Saturday)
  def self.create_current_week_contest
    today = Date.current
    # Find the most recent Sunday (start of week)
    start_of_week = today.beginning_of_week(:sunday)
    end_of_week = start_of_week + 6.days

    create!(
      start_date: start_of_week,
      end_date: end_of_week,
      status: 'active'
    )
  end

  # Check if contest is currently running
  def active?
    status == 'active' && Date.current.between?(start_date, end_date)
  end

  # Check if contest has ended
  def ended?
    Date.current > end_date
  end

  # Get leaderboard with scores
  # Returns array of { musician:, engagement_score:, vote_score:, total_score: }
  def leaderboard(limit = 10)
    musicians = Musician.includes(:user, :followers, :endorsements, :shoutouts, :musician_shorts)

    scored = musicians.map do |musician|
      engagement = calculate_engagement_score(musician)
      votes = vote_count_for(musician)
      {
        musician: musician,
        engagement_score: engagement,
        vote_score: votes * 10, # Each vote worth 10 points
        total_score: engagement + (votes * 10)
      }
    end

    scored.sort_by { |s| -s[:total_score] }.first(limit)
  end

  # Count votes for a musician in this contest
  def vote_count_for(musician)
    mainstage_votes.where(musician: musician).count
  end

  # Check if user has voted in this contest
  def voted_by?(user)
    return false unless user
    mainstage_votes.exists?(user: user)
  end

  # Get who the user voted for
  def vote_for(user)
    return nil unless user
    mainstage_votes.find_by(user: user)&.musician
  end

  # Finalize contest and determine winner
  def finalize!
    return if status == 'completed'

    winner_data = leaderboard(1).first
    return unless winner_data

    MainstageWinner.create!(
      mainstage_contest: self,
      musician: winner_data[:musician],
      final_score: winner_data[:total_score],
      engagement_score: winner_data[:engagement_score],
      vote_score: winner_data[:vote_score]
    )

    update!(status: 'completed')
  end

  private

  def calculate_engagement_score(musician)
    contest_period = start_date.beginning_of_day..end_date.end_of_day
    account_cutoff = start_date - ACCOUNT_AGE_REQUIREMENT

    # Track points per user to enforce cap
    user_points = Hash.new(0)

    total = 0

    # Follows: 5 points each
    musician.follows.where(created_at: contest_period).includes(:follower).each do |follow|
      next unless eligible_user?(follow.follower, account_cutoff)
      points = add_capped_points(user_points, follow.follower_id, 5)
      total += points
    end

    # Endorsements: 3 points each
    musician.endorsements.where(created_at: contest_period).each do |endorsement|
      next unless eligible_user?(endorsement.user, account_cutoff)
      points = add_capped_points(user_points, endorsement.user_id, 3)
      total += points
    end

    # Shoutouts: 8 points each
    musician.shoutouts.where(created_at: contest_period).each do |shoutout|
      next unless eligible_user?(shoutout.user, account_cutoff)
      points = add_capped_points(user_points, shoutout.user_id, 8)
      total += points
    end

    # Short likes: 2 points each
    ShortLike.joins(:musician_short)
             .where(musician_shorts: { musician_id: musician.id })
             .where(created_at: contest_period)
             .each do |like|
      next unless eligible_user?(like.user, account_cutoff)
      points = add_capped_points(user_points, like.user_id, 2)
      total += points
    end

    total
  end

  # Check if user account is old enough to count
  def eligible_user?(user, account_cutoff)
    return false unless user
    user.created_at <= account_cutoff
  end

  # Add points but cap at MAX_POINTS_PER_USER per user
  def add_capped_points(user_points, user_id, points)
    current = user_points[user_id]
    return 0 if current >= MAX_POINTS_PER_USER

    allowed = [points, MAX_POINTS_PER_USER - current].min
    user_points[user_id] += allowed
    allowed
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'must be after start date') if end_date <= start_date
  end
end
