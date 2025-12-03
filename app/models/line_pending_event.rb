class LinePendingEvent < ApplicationRecord
  belongs_to :line_band_connection
  belongs_to :suggested_by, class_name: 'User', optional: true

  enum status: {
    pending: 'pending',
    confirmed: 'confirmed',
    cancelled: 'cancelled'
  }

  validates :event_type, presence: true
  validates :date, presence: true

  def confirm!
    return false unless pending?

    band = line_band_connection.band

    band_event = band.band_events.create!(
      title: title.presence || "#{event_type.titleize} from LINE",
      event_type: event_type,
      date: date,
      start_time: start_time,
      end_time: end_time,
      location: location
    )

    update!(status: :confirmed)
    band_event
  end

  def cancel!
    update!(status: :cancelled)
  end
end
