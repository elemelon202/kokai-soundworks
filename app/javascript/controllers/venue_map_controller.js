import { Controller } from "@hotwired/stimulus"

// ============================================================================
// VENUE MAP CONTROLLER
// ============================================================================
// This Stimulus controller handles the interactive Mapbox map on the venues
// index page. It displays venue locations as pins on the map:
// - Green pins: Venues the user has played at
// - Muted red pins: Venues the user hasn't played at yet
//
// The map is collapsible - when expanded, the venue cards switch to a
// vertical layout alongside the map.
// ============================================================================

export default class extends Controller {
  // Define the HTML elements this controller interacts with
  static targets = [
    "container",     // The map container div
    "toggle",        // The expand/collapse button
    "cardsSection"   // The section containing venue cards (for layout switching)
  ]

  // Define the data values passed from the HTML
  static values = {
    apiKey: String,           // Mapbox API key from environment
    venues: Array,            // Array of venue objects with lat/lng
    playedVenueIds: Array,    // IDs of venues the user has played at
    userLat: Number,          // User's latitude (for centering map)
    userLng: Number           // User's longitude (for centering map)
  }

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  connect() {
    // Called when the controller is attached to the DOM
    // Always start collapsed - this fixes the issue where Turbo caches
    // the page with the map expanded and shows a blank space on return
    this.isExpanded = false
    this.map = null

    // Remove expanded class in case Turbo cached the page with it
    this.containerTarget.classList.remove("venue-map--expanded")
    this.toggleTarget.innerHTML = '<i class="fa-solid fa-map"></i> Show Map'
  }

  disconnect() {
    // Called when the controller is removed from the DOM
    // Clean up the map to prevent memory leaks
    if (this.map) {
      this.map.remove()
      this.map = null
    }

    // Reset to collapsed state for clean Turbo caching
    this.containerTarget.classList.remove("venue-map--expanded")
  }

  // ============================================================================
  // TOGGLE MAP VISIBILITY
  // ============================================================================

  toggle() {
    // Called when user clicks the expand/collapse button
    this.isExpanded = !this.isExpanded

    if (this.isExpanded) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  expand() {
    // Show the map container
    this.containerTarget.classList.add("venue-map--expanded")
    this.toggleTarget.innerHTML = '<i class="fa-solid fa-chevron-up"></i> Hide Map'

    // Switch cards to vertical layout
    if (this.hasCardsSectionTarget) {
      this.cardsSectionTarget.classList.add("venue-cards--vertical")
    }

    // Initialize the map if this is the first time expanding
    if (!this.map) {
      // Delay to ensure container is fully visible and has dimensions
      // before initializing Mapbox (it needs a sized container)
      setTimeout(() => {
        this.initializeMap()
        // Resize again after a short delay to ensure proper rendering
        setTimeout(() => {
          if (this.map) this.map.resize()
        }, 200)
      }, 150)
    } else {
      // Map already exists, just resize it to fit the container
      this.map.resize()
    }
  }

  collapse() {
    // Hide the map container
    this.containerTarget.classList.remove("venue-map--expanded")
    this.toggleTarget.innerHTML = '<i class="fa-solid fa-map"></i> Show Map'

    // Switch cards back to horizontal carousel layout
    if (this.hasCardsSectionTarget) {
      this.cardsSectionTarget.classList.remove("venue-cards--vertical")
    }
  }

  // ============================================================================
  // MAP INITIALIZATION
  // ============================================================================

  initializeMap() {
    // Set the Mapbox access token (required for API calls)
    mapboxgl.accessToken = this.apiKeyValue

    // Calculate the center of the map
    // If user location is provided, center on that
    // Otherwise, calculate the center from all venue locations
    const center = this.calculateMapCenter()

    // Create the Mapbox map instance
    this.map = new mapboxgl.Map({
      container: this.containerTarget,  // HTML element to render map in
      style: 'mapbox://styles/mapbox/dark-v11',  // Dark theme to match site
      center: center,  // [longitude, latitude]
      zoom: 10  // Initial zoom level (higher = more zoomed in)
    })

    // Add navigation controls (zoom buttons, compass)
    this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')

    // Wait for map to load before adding markers
    this.map.on('load', () => {
      this.addVenueMarkers()
    })
  }

  calculateMapCenter() {
    // If user location is provided, use that as center
    if (this.hasUserLatValue && this.hasUserLngValue && this.userLatValue && this.userLngValue) {
      return [this.userLngValue, this.userLatValue]
    }

    // Otherwise, calculate center from venue locations
    const venues = this.venuesValue || []
    if (venues.length === 0) {
      // Default to Tokyo if no venues
      return [139.6917, 35.6895]
    }

    // Calculate average of all venue coordinates
    const sumLat = venues.reduce((sum, v) => sum + (v.latitude || 0), 0)
    const sumLng = venues.reduce((sum, v) => sum + (v.longitude || 0), 0)

    return [sumLng / venues.length, sumLat / venues.length]
  }

  // ============================================================================
  // VENUE MARKERS
  // ============================================================================

  addVenueMarkers() {
    const venues = this.venuesValue || []
    const playedIds = this.playedVenueIdsValue || []

    venues.forEach(venue => {
      // Skip venues without coordinates
      if (!venue.latitude || !venue.longitude) return

      // Determine if this is a played venue (green) or not (muted red)
      const isPlayed = playedIds.includes(venue.id)

      // Create a custom marker element
      const markerEl = document.createElement('div')
      markerEl.className = isPlayed ? 'venue-marker venue-marker--played' : 'venue-marker venue-marker--unplayed'

      // Add the marker to the map
      const marker = new mapboxgl.Marker({
        element: markerEl,
        anchor: 'bottom'  // Pin points down from bottom of element
      })
        .setLngLat([venue.longitude, venue.latitude])
        .setPopup(this.createPopup(venue, isPlayed))  // Popup on click
        .addTo(this.map)
    })
  }

  createPopup(venue, isPlayed) {
    // Create the popup content that shows when a marker is clicked
    const playedBadge = isPlayed
      ? '<span class="venue-popup-badge venue-popup-badge--played"><i class="fa-solid fa-check"></i> Played here</span>'
      : ''

    const html = `
      <div class="venue-popup">
        <h4 class="venue-popup-name">${venue.name}</h4>
        ${playedBadge}
        <p class="venue-popup-address">
          <i class="fa-solid fa-location-dot"></i> ${venue.address || ''}, ${venue.city || ''}
        </p>
        <p class="venue-popup-capacity">
          <i class="fa-solid fa-users"></i> Capacity: ${venue.capacity || 'N/A'}
        </p>
        <a href="/venues/${venue.id}" class="venue-popup-link">View Details →</a>
      </div>
    `

    return new mapboxgl.Popup({
      offset: 25,  // Offset from marker
      closeButton: true,
      closeOnClick: false
    }).setHTML(html)
  }
}
