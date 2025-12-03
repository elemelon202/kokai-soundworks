# Configure Geocoder for testing - use stub to avoid external API calls
Geocoder.configure(lookup: :test)

# Add default test stubs
Geocoder::Lookup::Test.add_stub(
  "123 Main Street, Los Angeles", [
    {
      'coordinates'  => [34.0522, -118.2437],
      'address'      => '123 Main Street, Los Angeles, CA',
      'city'         => 'Los Angeles',
      'state'        => 'California',
      'country'      => 'United States',
      'country_code' => 'US'
    }
  ]
)

# Default stub for any address not specifically stubbed
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'coordinates'  => [35.6762, 139.6503],
      'address'      => 'Tokyo, Japan',
      'city'         => 'Tokyo',
      'country'      => 'Japan',
      'country_code' => 'JP'
    }
  ]
)
