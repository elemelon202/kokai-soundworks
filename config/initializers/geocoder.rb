# ============================================================================
# GEOCODER CONFIGURATION
# ============================================================================
# This configures the Geocoder gem to use Mapbox as the geocoding service.
# Mapbox converts addresses (like "123 Main St, Tokyo") into latitude/longitude
# coordinates that can be plotted on a map.
#
# We use Mapbox because:
# 1. We're already using Mapbox GL JS for displaying the map
# 2. It provides accurate geocoding results
# 3. The same API key works for both mapping and geocoding
# ============================================================================

Geocoder.configure(
  # Use Mapbox as the geocoding lookup service
  lookup: :mapbox,

  # The API key is stored in .env file as MAPBOX_API_KEY for security
  # Never commit API keys directly in code!
  api_key: ENV['MAPBOX_API_KEY'],

  # Timeout settings to prevent hanging requests
  timeout: 5, # seconds

  # Use HTTPS for secure API requests
  use_https: true,

  # Cache results to reduce API calls (uses Rails cache)
  # This means if we look up the same address twice, we use the cached result
  cache: Rails.cache,

  # How long to keep cached results (1 day)
  cache_options: {
    expiration: 1.day
  }
)
