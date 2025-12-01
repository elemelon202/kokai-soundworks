class Venue < ApplicationRecord
  belongs_to :user
  has_many :gigs, dependent: :destroy
  has_many_attached :photos

  # ============================================================================
  # GEOCODING SETUP (using the 'geocoder' gem)
  # ============================================================================
  # This automatically converts a venue's address into latitude/longitude
  # coordinates, which are needed to display pins on the Mapbox map.
  #
  # How it works:
  # 1. geocoded_by :full_address - tells Geocoder which method provides the
  #    address string to look up (e.g., "123 Main St, Tokyo")
  # 2. after_validation :geocode - automatically fetches lat/lng from an
  #    external geocoding API whenever the venue is saved
  # 3. The if: :should_geocode? condition prevents unnecessary API calls
  #    by only geocoding when the address actually changed or coordinates
  #    are missing
  # ============================================================================
  geocoded_by :full_address
  after_validation :geocode, if: :should_geocode?

  # Combines address and city into a single string for geocoding lookup
  # Example: "123 Main St" + "Tokyo" => "123 Main St, Tokyo"
  # The .compact removes any nil values before joining
  def full_address
    [address, city].compact.join(', ')
  end

  private

  # Determines whether we need to call the geocoding API
  # Returns true if:
  #   - The venue has an address or city AND
  #   - Either the address/city is being changed OR coordinates are missing
  # This prevents unnecessary API calls when editing other venue fields
  def should_geocode?
    has_address = address.present? || city.present?
    address_changing = will_save_change_to_address? || will_save_change_to_city?
    missing_coordinates = latitude.nil? && longitude.nil?

    has_address && (address_changing || missing_coordinates)
  end
end
