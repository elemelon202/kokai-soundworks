# YouTube Shorts Feature Implementation Plan

## Phase 1: Database & Model Setup

### Step 1: Create MusicianShort Model

Run migration:
```bash
# Generate a new model with Active Record migration
# - musician:references creates a foreign key column (musician_id) and index
# - title:string creates a varchar column (default 255 chars)
# - description:text creates a text column for longer content
# - position:integer for manual ordering of shorts
bin/rails generate model MusicianShort musician:references title:string description:text position:integer
```

In the model file (`app/models/musician_short.rb`):
```ruby
class MusicianShort < ApplicationRecord
  # Sets up a belongs_to association - each short must have a musician
  # Creates musician and musician_id methods, validates presence by default in Rails 5+
  belongs_to :musician

  # Active Storage attachment - stores video in configured storage (local/S3/etc)
  # Creates video, video.attach, video.attached? methods
  has_one_attached :video

  # Requires video to be present before saving
  validates :video, presence: true

  # Title required, capped at 100 chars (good for UI display)
  validates :title, presence: true, length: { maximum: 100 }

  # Position must be integer >= 0 if provided, but can be nil
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Custom validation method for video file type/size
  validate :acceptable_video

  # Auto-sort all queries: first by position (nulls last), then newest first
  # WARNING: default_scope can cause unexpected behavior - consider using named scopes instead
  default_scope { order(position: :asc, created_at: :desc) }

  private

  # Custom validator ensures only allowed video formats and reasonable file size
  def acceptable_video
    # Skip validation if no video attached (presence validation handles that)
    return unless video.attached?

    # Only allow common web-compatible video formats
    # video/mp4 = .mp4, video/webm = .webm, video/quicktime = .mov
    unless video.content_type.in?(%w[video/mp4 video/webm video/quicktime])
      errors.add(:video, 'must be an MP4, WebM, or MOV file')
    end

    # Prevent massive uploads - 100MB to 200MB is supposed to be ok
    # Rails helper: 100.megabytes = 104_857_600 bytes
    if video.byte_size > 100.megabytes
      errors.add(:video, 'must be less than 100MB')
    end
  end
end
```

### Step 2: Update Musician Model

In `app/models/musician.rb`, add:
```ruby
# One musician can have many shorts
# dependent: :destroy = when musician is deleted, delete all their shorts too
has_many :musician_shorts, dependent: :destroy

# Named scope to find only musicians who have uploaded at least one short
# joins performs INNER JOIN, distinct prevents duplicates if musician has multiple shorts
scope :with_shorts, -> { joins(:musician_shorts).distinct }
```

---

## Phase 2: Backend (Controllers & Routes)

### Step 3: Create Routes

In `config/routes.rb`:
```ruby
# Public discovery page - only index action needed
# path: 'discover' changes URL from /musician_shorts to /discover
# Generates: GET /discover -> musician_shorts#index
resources :musician_shorts, only: [:index], path: 'discover'

# Nested routes for CRUD operations on a musician's shorts
# Keeps shorts scoped to their musician in URLs
resources :musicians do
  # path: 'shorts' shortens URLs from /musician_shorts to /shorts
  # controller: 'musician_shorts' routes to MusicianShortsController
  # Generates:
  #   GET    /musicians/:musician_id/shorts/new     -> new
  #   POST   /musicians/:musician_id/shorts         -> create
  #   GET    /musicians/:musician_id/shorts/:id/edit -> edit
  #   PATCH  /musicians/:musician_id/shorts/:id     -> update
  #   DELETE /musicians/:musician_id/shorts/:id     -> destroy
  resources :shorts, controller: 'musician_shorts', only: [:new, :create, :edit, :update, :destroy] do
    # collection routes don't require :id parameter
    # Generates: PATCH /musicians/:musician_id/shorts/reorder -> reorder
    collection do
      patch :reorder
    end
  end
end
```

### Step 4: Create MusicianShortsController

Create `app/controllers/musician_shorts_controller.rb`:
```ruby
class MusicianShortsController < ApplicationController
  # Run set_musician before these actions to load @musician from URL params
  before_action :set_musician, only: [:new, :create, :edit, :update, :destroy, :reorder]

  # Run set_short before these actions to load @short (requires @musician first)
  before_action :set_short, only: [:edit, :update, :destroy]

  # GET /discover - Main discovery page for browsing all shorts
  def index
    # Load musicians who have shorts, eager-load associations to avoid N+1 queries
    # includes() loads video_attachment and blob in same query batch
    @musicians_with_shorts = Musician.with_shorts
                                     .includes(musician_shorts: { video_attachment: :blob })
                                     .limit(50)  # Pagination - only load first 50

    # Separate query for all shorts in chronological order
    # Used for the swipeable carousel view
    @shorts = MusicianShort.includes(:musician, video_attachment: :blob)
                           .order(created_at: :desc)  # Newest first
                           .limit(100)  # Cap results for performance
  end

  # GET /musicians/:musician_id/shorts/new - Form to upload new short
  def new
    # Build empty short associated with musician (sets musician_id)
    @short = @musician.musician_shorts.build
  end

  # POST /musicians/:musician_id/shorts - Handle form submission
  def create
    # Build short with permitted params, auto-associates with musician
    @short = @musician.musician_shorts.build(short_params)

    if @short.save
      # Success: redirect to musician's profile with flash message
      redirect_to musician_path(@musician), notice: 'Short uploaded successfully!'
    else
      # Failure: re-render form with validation errors
      # status: :unprocessable_entity (422) required for Turbo compatibility
      render :new, status: :unprocessable_entity
    end
  end

  # GET /musicians/:musician_id/shorts/:id/edit - Form to edit existing short
  def edit
    # @short already loaded by before_action, just render the form
  end

  # PATCH /musicians/:musician_id/shorts/:id - Handle edit form submission
  def update
    if @short.update(short_params)
      redirect_to musician_path(@musician), notice: 'Short updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /musicians/:musician_id/shorts/:id - Remove a short
  def destroy
    @short.destroy  # Also removes attached video from storage
    redirect_to musician_path(@musician), notice: 'Short deleted.'
  end

  # PATCH /musicians/:musician_id/shorts/reorder - AJAX endpoint for drag-drop reordering
  def reorder
    # Expects params[:short_ids] = array of IDs in new order
    # each_with_index gives (id, 0), (id, 1), (id, 2)...
    params[:short_ids].each_with_index do |id, index|
      # Find within musician's shorts (security: can't reorder other musicians' shorts)
      @musician.musician_shorts.find(id).update(position: index)
    end
    # Return 200 OK with empty body (AJAX response)
    head :ok
  end

  private

  # Load musician from URL parameter, used by nested routes
  def set_musician
    @musician = Musician.find(params[:musician_id])
    # Raises ActiveRecord::RecordNotFound (404) if not found
  end

  # Load specific short within musician's shorts
  def set_short
    # Scoped find: only finds shorts belonging to @musician
    # Prevents accessing other musicians' shorts by ID manipulation
    @short = @musician.musician_shorts.find(params[:id])
  end

  # Strong parameters: whitelist allowed form fields
  # Prevents mass assignment vulnerabilities
  def short_params
    params.require(:musician_short).permit(:title, :description, :video, :position)
  end
end
```

---

## Phase 3: Frontend (Views)

### Step 5: Discovery Page (Index View)

Create `app/views/musician_shorts/index.html.erb`:
```erb
<%# Main discovery page for browsing all shorts %>
<div class="shorts-discovery" data-controller="shorts-carousel">
  <h1>Discover</h1>

  <%# Vertical scrolling feed of shorts %>
  <div class="shorts-feed" data-shorts-carousel-target="feed">
    <% @shorts.each_with_index do |short, index| %>
      <div class="short-card"
           data-shorts-carousel-target="card"
           data-index="<%= index %>">

        <%# Video container with Stimulus video player controller %>
        <div class="video-container" data-controller="video-player">
          <%# HTML5 video element - playsinline required for iOS autoplay %>
          <%= video_tag url_for(short.video),
                        controls: false,
                        playsinline: true,
                        loop: true,
                        muted: true,
                        preload: "metadata",
                        data: {
                          video_player_target: "video",
                          action: "click->video-player#toggle"
                        } %>

          <%# Play/pause overlay button %>
          <button class="play-overlay"
                  data-video-player-target="playButton"
                  data-action="click->video-player#toggle">
            <span class="play-icon">▶</span>
            <span class="pause-icon">❚❚</span>
          </button>

          <%# Progress bar %>
          <div class="progress-bar" data-video-player-target="progressBar">
            <div class="progress-fill" data-video-player-target="progressFill"></div>
          </div>
        </div>

        <%# Short info overlay %>
        <div class="short-info">
          <%= link_to short.musician.name, musician_path(short.musician), class: "musician-name" %>
          <h3 class="short-title"><%= short.title %></h3>
          <% if short.description.present? %>
            <p class="short-description"><%= truncate(short.description, length: 100) %></p>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>

  <%# Navigation arrows for desktop %>
  <button class="nav-arrow nav-prev"
          data-action="click->shorts-carousel#previous"
          data-shorts-carousel-target="prevButton">
    ↑
  </button>
  <button class="nav-arrow nav-next"
          data-action="click->shorts-carousel#next"
          data-shorts-carousel-target="nextButton">
    ↓
  </button>
</div>
```

### Step 6: Upload Form (New View)

Create `app/views/musician_shorts/new.html.erb`:
```erb
<div class="short-form-container">
  <h1>Upload a Short</h1>

  <%= render 'form', short: @short, musician: @musician %>
</div>
```

### Step 7: Edit Form (Edit View)

Create `app/views/musician_shorts/edit.html.erb`:
```erb
<div class="short-form-container">
  <h1>Edit Short</h1>

  <%= render 'form', short: @short, musician: @musician %>

  <div class="current-video">
    <h3>Current Video</h3>
    <%= video_tag url_for(@short.video), controls: true, style: "max-width: 300px;" if @short.video.attached? %>
  </div>
</div>
```

### Step 8: Shared Form Partial

Create `app/views/musician_shorts/_form.html.erb`:
```erb
<%# Form partial shared between new and edit views %>
<%# data-controller attaches Stimulus controller for preview functionality %>
<%= form_with model: [musician, short],
              data: { controller: "video-upload" } do |form| %>

  <%# Display validation errors %>
  <% if short.errors.any? %>
    <div class="error-messages">
      <h4><%= pluralize(short.errors.count, "error") %> prevented this short from being saved:</h4>
      <ul>
        <% short.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.label :title %>
    <%= form.text_field :title,
                        class: "form-control",
                        placeholder: "Give your short a title",
                        maxlength: 100 %>
  </div>

  <div class="form-group">
    <%= form.label :description %>
    <%= form.text_area :description,
                       class: "form-control",
                       placeholder: "Add a description (optional)",
                       rows: 3 %>
  </div>

  <div class="form-group">
    <%= form.label :video %>
    <%# direct_upload: true enables Active Storage direct upload to S3 %>
    <%= form.file_field :video,
                        accept: "video/mp4,video/webm,video/quicktime",
                        class: "form-control",
                        data: {
                          video_upload_target: "input",
                          action: "change->video-upload#preview"
                        } %>
    <small class="form-text">MP4, WebM, or MOV. Max 100MB.</small>

    <%# Video preview container (hidden until file selected) %>
    <div class="video-preview"
         data-video-upload-target="preview"
         style="display: none;">
      <video controls data-video-upload-target="previewVideo"></video>
    </div>
  </div>

  <div class="form-group">
    <%= form.label :position, "Display Order (optional)" %>
    <%= form.number_field :position,
                          class: "form-control",
                          min: 0,
                          placeholder: "Leave blank for automatic ordering" %>
  </div>

  <div class="form-actions">
    <%= form.submit short.persisted? ? "Update Short" : "Upload Short",
                    class: "btn btn-primary",
                    data: { video_upload_target: "submitButton" } %>
    <%= link_to "Cancel", musician_path(musician), class: "btn btn-secondary" %>
  </div>
<% end %>
```

### Step 9: Musician Profile Shorts Section

Add to musician show view (`app/views/musicians/show.html.erb`):
```erb
<%# Shorts section on musician profile %>
<section class="musician-shorts" data-controller="shorts-reorder">
  <div class="section-header">
    <h2>Shorts</h2>
    <%# Show upload button only to the musician themselves %>
    <% if current_user&.musician == @musician %>
      <%= link_to "Upload Short", new_musician_short_path(@musician), class: "btn btn-primary" %>
    <% end %>
  </div>

  <% if @musician.musician_shorts.any? %>
    <div class="shorts-grid"
         data-shorts-reorder-target="grid"
         data-musician-id="<%= @musician.id %>">
      <% @musician.musician_shorts.each do |short| %>
        <div class="short-thumbnail"
             draggable="true"
             data-short-id="<%= short.id %>"
             data-action="dragstart->shorts-reorder#dragStart
                          dragover->shorts-reorder#dragOver
                          drop->shorts-reorder#drop">

          <%# Video thumbnail - shows first frame %>
          <%= video_tag url_for(short.video),
                        preload: "metadata",
                        muted: true,
                        class: "thumbnail-video" %>

          <div class="thumbnail-overlay">
            <span class="short-title"><%= short.title %></span>
          </div>

          <%# Edit/delete buttons for owner %>
          <% if current_user&.musician == @musician %>
            <div class="short-actions">
              <%= link_to "Edit", edit_musician_short_path(@musician, short), class: "btn-sm" %>
              <%= button_to "Delete", musician_short_path(@musician, short),
                            method: :delete,
                            class: "btn-sm btn-danger",
                            data: { confirm: "Are you sure?" } %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
  <% else %>
    <p class="no-shorts">No shorts uploaded yet.</p>
  <% end %>
</section>
```

---

## Phase 4: JavaScript (Stimulus Controllers)

### Step 10: Video Player Controller

Create `app/javascript/controllers/video_player_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

// Handles individual video playback controls
// Usage: data-controller="video-player" on video container
export default class extends Controller {
  // Define targets that can be referenced in the controller
  static targets = ["video", "playButton", "progressBar", "progressFill"]

  connect() {
    // Called when controller is connected to DOM
    this.playing = false

    // Update progress bar as video plays
    this.videoTarget.addEventListener("timeupdate", () => this.updateProgress())

    // Reset play button when video ends (if not looping)
    this.videoTarget.addEventListener("ended", () => this.handleEnded())
  }

  disconnect() {
    // Cleanup when controller disconnects
    this.pause()
  }

  // Toggle play/pause state
  toggle(event) {
    event?.preventDefault()

    if (this.playing) {
      this.pause()
    } else {
      this.play()
    }
  }

  play() {
    // Play the video and update UI state
    this.videoTarget.play()
    this.playing = true
    this.element.classList.add("is-playing")
  }

  pause() {
    // Pause the video and update UI state
    this.videoTarget.pause()
    this.playing = false
    this.element.classList.remove("is-playing")
  }

  // Update progress bar based on current playback position
  updateProgress() {
    if (!this.hasProgressFillTarget) return

    const percent = (this.videoTarget.currentTime / this.videoTarget.duration) * 100
    this.progressFillTarget.style.width = `${percent}%`
  }

  handleEnded() {
    this.playing = false
    this.element.classList.remove("is-playing")
  }

  // Seek to position when clicking progress bar
  seek(event) {
    if (!this.hasProgressBarTarget) return

    const rect = this.progressBarTarget.getBoundingClientRect()
    const percent = (event.clientX - rect.left) / rect.width
    this.videoTarget.currentTime = percent * this.videoTarget.duration
  }

  // Mute/unmute toggle
  toggleMute() {
    this.videoTarget.muted = !this.videoTarget.muted
    this.element.classList.toggle("is-muted", this.videoTarget.muted)
  }
}
```

### Step 11: Shorts Carousel Controller

Create `app/javascript/controllers/shorts_carousel_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

// Handles vertical scrolling/swiping through shorts feed
// Similar to TikTok/YouTube Shorts navigation
export default class extends Controller {
  static targets = ["feed", "card", "prevButton", "nextButton"]

  connect() {
    this.currentIndex = 0
    this.touchStartY = 0
    this.touchEndY = 0

    // Bind touch events for mobile swipe
    this.feedTarget.addEventListener("touchstart", (e) => this.handleTouchStart(e))
    this.feedTarget.addEventListener("touchend", (e) => this.handleTouchEnd(e))

    // Bind keyboard navigation
    document.addEventListener("keydown", this.handleKeydown.bind(this))

    // Intersection Observer for auto-play when card is visible
    this.setupIntersectionObserver()

    // Update navigation button states
    this.updateNavButtons()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
    this.observer?.disconnect()
  }

  // Set up Intersection Observer for lazy loading and auto-play
  setupIntersectionObserver() {
    // Options: trigger when 50% of card is visible
    const options = {
      root: this.feedTarget,
      threshold: 0.5
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        const card = entry.target
        const videoController = this.application.getControllerForElementAndIdentifier(
          card.querySelector("[data-controller='video-player']"),
          "video-player"
        )

        if (entry.isIntersecting) {
          // Card is visible - auto-play video
          videoController?.play()
          this.currentIndex = parseInt(card.dataset.index)
          this.updateNavButtons()
        } else {
          // Card left viewport - pause video
          videoController?.pause()
        }
      })
    }, options)

    // Observe all cards
    this.cardTargets.forEach((card) => this.observer.observe(card))
  }

  // Navigate to previous short
  previous() {
    if (this.currentIndex > 0) {
      this.goToIndex(this.currentIndex - 1)
    }
  }

  // Navigate to next short
  next() {
    if (this.currentIndex < this.cardTargets.length - 1) {
      this.goToIndex(this.currentIndex + 1)
    }
  }

  // Scroll to specific card index
  goToIndex(index) {
    const card = this.cardTargets[index]
    if (card) {
      card.scrollIntoView({ behavior: "smooth", block: "center" })
      this.currentIndex = index
      this.updateNavButtons()
    }
  }

  // Handle keyboard navigation (up/down arrows)
  handleKeydown(event) {
    if (event.key === "ArrowUp" || event.key === "k") {
      event.preventDefault()
      this.previous()
    } else if (event.key === "ArrowDown" || event.key === "j") {
      event.preventDefault()
      this.next()
    }
  }

  // Touch event handlers for mobile swipe
  handleTouchStart(event) {
    this.touchStartY = event.touches[0].clientY
  }

  handleTouchEnd(event) {
    this.touchEndY = event.changedTouches[0].clientY
    const diff = this.touchStartY - this.touchEndY
    const threshold = 50 // Minimum swipe distance

    if (Math.abs(diff) > threshold) {
      if (diff > 0) {
        // Swiped up - go to next
        this.next()
      } else {
        // Swiped down - go to previous
        this.previous()
      }
    }
  }

  // Update visibility/state of navigation buttons
  updateNavButtons() {
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.currentIndex === 0
    }
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.currentIndex >= this.cardTargets.length - 1
    }
  }
}
```

### Step 12: Video Upload Controller

Create `app/javascript/controllers/video_upload_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

// Handles video file selection and preview before upload
export default class extends Controller {
  static targets = ["input", "preview", "previewVideo", "submitButton"]

  connect() {
    // Optional: Set up direct upload progress indicator
    this.setupDirectUpload()
  }

  // Show video preview when file is selected
  preview() {
    const file = this.inputTarget.files[0]

    if (!file) {
      this.hidePreview()
      return
    }

    // Validate file type
    const allowedTypes = ["video/mp4", "video/webm", "video/quicktime"]
    if (!allowedTypes.includes(file.type)) {
      alert("Please select an MP4, WebM, or MOV file.")
      this.inputTarget.value = ""
      this.hidePreview()
      return
    }

    // Validate file size (100MB max)
    const maxSize = 100 * 1024 * 1024 // 100MB in bytes
    if (file.size > maxSize) {
      alert("File is too large. Maximum size is 100MB.")
      this.inputTarget.value = ""
      this.hidePreview()
      return
    }

    // Create object URL for preview
    const url = URL.createObjectURL(file)
    this.previewVideoTarget.src = url
    this.previewTarget.style.display = "block"

    // Clean up object URL when video loads
    this.previewVideoTarget.onloadeddata = () => {
      // Video is ready for preview
    }
  }

  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = "none"
    }
    if (this.hasPreviewVideoTarget) {
      this.previewVideoTarget.src = ""
    }
  }

  // Set up Active Storage direct upload progress
  setupDirectUpload() {
    // Listen for direct upload events
    this.element.addEventListener("direct-upload:start", (event) => {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.value = "Uploading..."
    })

    this.element.addEventListener("direct-upload:progress", (event) => {
      const { progress } = event.detail
      this.submitButtonTarget.value = `Uploading... ${Math.round(progress)}%`
    })

    this.element.addEventListener("direct-upload:end", (event) => {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.value = "Upload Short"
    })

    this.element.addEventListener("direct-upload:error", (event) => {
      event.preventDefault()
      const { error } = event.detail
      alert(`Upload failed: ${error}`)
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.value = "Upload Short"
    })
  }
}
```

### Step 13: Shorts Reorder Controller (Drag & Drop)

Create `app/javascript/controllers/shorts_reorder_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

// Handles drag-and-drop reordering of shorts on musician profile
export default class extends Controller {
  static targets = ["grid"]

  connect() {
    this.draggedItem = null
  }

  // Called when drag starts
  dragStart(event) {
    this.draggedItem = event.target.closest("[data-short-id]")
    event.dataTransfer.effectAllowed = "move"

    // Add visual feedback
    this.draggedItem.classList.add("is-dragging")
  }

  // Called when dragging over a valid drop target
  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest("[data-short-id]")
    if (target && target !== this.draggedItem) {
      // Determine if we should insert before or after
      const rect = target.getBoundingClientRect()
      const midpoint = rect.left + rect.width / 2

      if (event.clientX < midpoint) {
        target.parentNode.insertBefore(this.draggedItem, target)
      } else {
        target.parentNode.insertBefore(this.draggedItem, target.nextSibling)
      }
    }
  }

  // Called when item is dropped
  drop(event) {
    event.preventDefault()

    if (this.draggedItem) {
      this.draggedItem.classList.remove("is-dragging")
      this.saveOrder()
      this.draggedItem = null
    }
  }

  // Save new order to server via AJAX
  async saveOrder() {
    const musicianId = this.gridTarget.dataset.musicianId

    // Get all short IDs in current order
    const shortIds = Array.from(this.gridTarget.querySelectorAll("[data-short-id]"))
      .map(el => el.dataset.shortId)

    try {
      const response = await fetch(`/musicians/${musicianId}/shorts/reorder`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ short_ids: shortIds })
      })

      if (!response.ok) {
        throw new Error("Failed to save order")
      }
    } catch (error) {
      console.error("Error saving order:", error)
      alert("Failed to save new order. Please try again.")
    }
  }
}
```

### Step 14: Register Stimulus Controllers

Update `app/javascript/controllers/index.js`:
```javascript
import { application } from "./application"

// Import and register all controllers
import VideoPlayerController from "./video_player_controller"
import ShortsCarouselController from "./shorts_carousel_controller"
import VideoUploadController from "./video_upload_controller"
import ShortsReorderController from "./shorts_reorder_controller"

application.register("video-player", VideoPlayerController)
application.register("shorts-carousel", ShortsCarouselController)
application.register("video-upload", VideoUploadController)
application.register("shorts-reorder", ShortsReorderController)

// ... other existing controllers
```

---

## Phase 5: Styling (CSS/SCSS)

*TODO: Add styles for shorts discovery page, video player, and carousel*
