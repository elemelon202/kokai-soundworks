class BandEvent < ApplicationRecord
  belongs_to :band

  enum event_type: { rehearsal: 0, meeting: 1, recording: 2, other: 3}

  validates :title, presence: true
  validates :date, presence: true
  validates :event_type, presence: true

  scope :upcoming, -> { where('date >= ?', Date.current).order(:date, :start_time) }
  scope :past, -> { where('date < ?', Date.current).order(date: :desc) }
end
