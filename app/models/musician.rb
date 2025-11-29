include PgSearch::Model # <-- needed for search on musicians index page -- kyle

class Musician < ApplicationRecord
  # involvements has to come first
  has_many :involvements, dependent: :destroy
  has_many :bands, through: :involvements
  belongs_to :user
  has_one_attached :avatar
  has_one_attached :banner
  has_many_attached :images
  has_many_attached :videos
  has_many_attached :media # keeping for backwards compatibility
  has_many :musician_shorts, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy # Enable follow functionality
  has_many :followers, through: :follows, source: :follower # Users who follow this musician
  has_many :profile_views, as: :viewable, dependent: :destroy
  has_many :profile_saves, as: :saveable, class_name: 'ProfileSave', dependent: :destroy
  has_many :endorsements, dependent: :destroy
  has_many :endorsers, through: :endorsements, source: :user
  has_many :shoutouts, dependent: :destroy
  has_many :shouters, through: :shoutouts, source: :user
  has_many :activities, dependent: :destroy
  has_many :mainstage_votes, dependent: :destroy
  has_many :mainstage_wins, class_name: 'MainstageWinner', dependent: :destroy

  validates :name, presence: true

  scope :with_shorts, -> { joins(:musician_shorts).distinct }

  # for searching on the musicians index page -- kyle
  pg_search_scope :search_by_all,
  against: [:name, :instrument, :location, :styles],
  associated_against: {
    bands: [:name]
  },
  using: {
    tsearch: { prefix: true }
  }

  # Returns bands where this musician is the leader (band creator)
  def led_bands
    bands.where(user_id: user_id)
  end

  # Check if musician is a leader of any band
  def band_leader?
    led_bands.exists?
  end

  # Get endorsement count for a specific skill
  def endorsement_count_for(skill)
    endorsements.for_skill(skill).count
  end

  # Get top endorsed skills
  def top_skills(limit = 5)
    endorsements.group(:skill).order('count_all DESC').limit(limit).count
  end

  # Check if user has endorsed this musician for a skill
  def endorsed_by?(user, skill)
    return false unless user
    endorsements.exists?(user: user, skill: skill)
  end

  # Check if user has given a shoutout to this musician
  def shoutout_from?(user)
    return false unless user
    shoutouts.exists?(user: user)
  end

  # Check if musician has won MAINSTAGE
  def mainstage_winner?
    mainstage_wins.exists?
  end

  # Get total MAINSTAGE wins count
  def mainstage_win_count
    mainstage_wins.count
  end

  # Get most recent MAINSTAGE win
  def latest_mainstage_win
    mainstage_wins.recent.first
  end
end
