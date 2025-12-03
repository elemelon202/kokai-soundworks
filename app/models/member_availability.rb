class MemberAvailability < ApplicationRecord
  belongs_to :musician
  belongs_to :band

  enum status: { unavailable: 0, tentative: 1 }

  validates :start_date, presence: true
  validate :end_date_after_start_date

  # Scope: Find availabilities that include a specific date
  # Example: MemberAvailability.for_date(Date.today) returns all availabilities
  # where the date falls between start_date and end_date (or just matches start_date if no end_date)
  scope :for_date, ->(date) { where("start_date <= ? AND (end_date >= ? OR end_date IS NULL)", date, date) }

  # Scope: Find availabilities that overlap with a date range
  # Example: MemberAvailability.for_date_range(Date.today, Date.today + 7.days)
  # returns availabilities that overlap with the next week
  scope :for_date_range, ->(range_start, range_end) { where("start_date <= ? AND (end_date >= ? OR end_date IS NULL)", range_end, range_start) }

  # Returns an array of all dates covered by this availability
  # Example: If start_date is Dec 5 and end_date is Dec 8, returns [Dec 5, Dec 6, Dec 7, Dec 8]
  def date_range
    return [start_date] if end_date.nil?
    (start_date..end_date).to_a
  end

  private

  # Validation: Ensures end_date comes after start_date
  def end_date_after_start_date
    return if end_date.nil? || start_date.nil?
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
