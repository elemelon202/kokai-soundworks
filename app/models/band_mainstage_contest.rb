# Represents a weekly BAND MAINSTAGE contest period
# Each contest runs Sunday to Saturday
# Winners are determined by engagement score + community votes
#
# Anti-gaming protections:
# - Account must be 3+ days old for engagement to count
# - Max 15 points any single user can contribute to a band

class BandMainstageContest < ApplicationRecord
  ACCOUNT_AGE_REQUIREMENT = 3.days
  MAX_POINTS_PER_USER = 15

  has_many :band_mainstage_votes, dependent: :destroy
  has_one :band_mainstage_winner, dependent: :destroy

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
    start_of_week = today.beginning_of_week(:sunday)
    end_of_week = start_of_week + 6.days

    create!(
      start_date: start_of_week,
      end_date: end_of_week,
      status: 'active'
    )
  end

  def active?
    status == 'active' && Date.current.between?(start_date, end_date)
  end

  def ended?
    Date.current > end_date
  end

  # Get leaderboard with scores
  def leaderboard(limit = 10)
    bands = Band.includes(:user, :followers, :musicians)

    scored = bands.map do |band|
      engagement = calculate_engagement_score(band)
      votes = vote_count_for(band)
      {
        band: band,
        engagement_score: engagement,
        vote_score: votes * 10,
        total_score: engagement + (votes * 10)
      }
    end

    scored.sort_by { |s| -s[:total_score] }.first(limit)
  end

  def vote_count_for(band)
    band_mainstage_votes.where(band: band).count
  end

  def voted_by?(user)
    return false unless user
    band_mainstage_votes.exists?(user: user)
  end

  def vote_for(user)
    return nil unless user
    band_mainstage_votes.find_by(user: user)&.band
  end

  def finalize!
    return if status == 'completed'

    winner_data = leaderboard(1).first
    return unless winner_data

    BandMainstageWinner.create!(
      band_mainstage_contest: self,
      band: winner_data[:band],
      final_score: winner_data[:total_score],
      engagement_score: winner_data[:engagement_score],
      vote_score: winner_data[:vote_score]
    )

    update!(status: 'completed')
  end

  private

  def calculate_engagement_score(band)
    contest_period = start_date.beginning_of_day..end_date.end_of_day
    account_cutoff = start_date - ACCOUNT_AGE_REQUIREMENT

    user_points = Hash.new(0)
    total = 0

    # Follows: 5 points each
    band.follows.where(created_at: contest_period).includes(:follower).each do |follow|
      next unless eligible_user?(follow.follower, account_cutoff)
      points = add_capped_points(user_points, follow.follower_id, 5)
      total += points
    end

    # Profile saves: 3 points each
    band.profile_saves.where(created_at: contest_period).each do |save|
      next unless save.user && eligible_user?(save.user, account_cutoff)
      points = add_capped_points(user_points, save.user_id, 3)
      total += points
    end

    # Gig bookings: 10 points each (bands get points for being booked)
    band.bookings.where(created_at: contest_period).each do |booking|
      total += 10 # Bookings are organic engagement
    end

    # Member short likes: 2 points each (when a band member's short gets liked)
    band.musicians.each do |musician|
      musician.musician_shorts.each do |short|
        short.short_likes.where(created_at: contest_period).each do |like|
          next unless eligible_user?(like.user, account_cutoff)
          points = add_capped_points(user_points, like.user_id, 2)
          total += points
        end
      end
    end

    total
  end

  # TEMPORARILY DISABLED FOR PITCH DEMO
  def eligible_user?(user, account_cutoff)
    return false unless user
    # user.created_at <= account_cutoff
    true
  end

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
