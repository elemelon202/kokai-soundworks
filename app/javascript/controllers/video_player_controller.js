import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="video-player"
export default class extends Controller {
  static targets = ["video", "playButton", "progressBar", "progressFill", "muteButton", "muteIcon"]

  connect() {
    this.playing = false

    if (this.hasVideoTarget) {
      this.videoTarget.addEventListener("timeupdate", () => this.updateProgress())
      this.videoTarget.addEventListener("ended", () => this.handleEnded())

      // Use IntersectionObserver for autoplay when video becomes visible
      this.observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.play()
          } else {
            this.pause()
          }
        })
      }, { threshold: 0.5 })

      this.observer.observe(this.element)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    this.pause()
  }

toggle(event) {
  event?.preventDefault()
  if (this.playing) {
    this.pause()
  } else {
    this.play()
  }
}

play() {
  if (this.hasVideoTarget) {
    this.videoTarget.play()
    this.playing = true
    if (this.hasPlayButtonTarget) {
      this.playButtonTarget.style.opacity = "0"
    }
  }
}

pause() {
  if (this.hasVideoTarget) {
    this.videoTarget.pause()
  }
  this.playing = false
  if (this.hasPlayButtonTarget) {
    this.playButtonTarget.style.opacity = "1"
  }
}

updateProgress() {
  if (!this.hasProgressFillTarget) return

  const percentage = (this.videoTarget.currentTime / this.videoTarget.duration) * 100
  this.progressFillTarget.style.width = `${percentage}%`
}

handleEnded() {
  this.playing = false
  this.element.classList.remove("is-playing")
}
// basically it allows you to seek the video by clicking on the progress bar. it is very clever and scales well with different screen sizes. no i did not know what this was when i wrote it. clientX and getBoundingClientRect are js methods. -sam
seek(event) {
  if (!this.hasProgressBarTarget) return // check if the progressBarTarget exists

  const rect = this.progressBarTarget.getBoundingClientRect() // get the size and position of the progress bar. getBoundingClientRect returns an object with properties like left, top, width, height, etc. relative to the viewport.
  const percent = (event.clientX - rect.left) / rect.width // calculate the percentage of the click position relative to the progress bar width.
  this.videoTarget.currentTime = percent * this.videoTarget.duration // set the video's current time based on the calculated percentage.
}

toggleMute() {
  if (!this.hasVideoTarget) return

  this.videoTarget.muted = !this.videoTarget.muted

  // Update mute icon
  if (this.hasMuteIconTarget) {
    if (this.videoTarget.muted) {
      this.muteIconTarget.classList.remove("fa-volume-high")
      this.muteIconTarget.classList.add("fa-volume-xmark")
    } else {
      this.muteIconTarget.classList.remove("fa-volume-xmark")
      this.muteIconTarget.classList.add("fa-volume-high")
    }
  }
}

showMute() {
  if (this.hasMuteButtonTarget) {
    this.muteButtonTarget.style.opacity = "1"
  }
}

hideMute() {
  if (this.hasMuteButtonTarget) {
    this.muteButtonTarget.style.opacity = "0"
  }
}
}
