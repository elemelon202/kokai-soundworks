include PgSearch::Model # <-- needed for search on musicians index page -- kyle

class Musician < ApplicationRecord
  # involvements has to come first
  has_many :involvements, dependent: :destroy
  has_many :bands, through: :involvements
  belongs_to :user
  has_many_attached :media

  validates :name, presence: true

  # for searching on the musicians index page -- kyle
  pg_search_scope :search_by_all,
  against: [:name, :instrument, :location, :styles],
  associated_against: {
    bands: [:name]
  },
  using: {
    tsearch: { prefix: true }
  }
end
