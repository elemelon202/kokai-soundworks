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
end
