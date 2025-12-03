class BandGig < ApplicationRecord
  belongs_to :band

  validates :name, presence: true
  validates :date, presence: true

  scope :upcoming, -> { where('date >= ?', Date.current).order(:date) }
  scope :past, -> { where('date < ?', Date.current).order(date: :desc) }
end
