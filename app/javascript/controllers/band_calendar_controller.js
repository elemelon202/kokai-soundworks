import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "modal", "modalTitle", "modalBody", "eventForm"]
  static values = {
    gigs: Array,
    bandEvents: Array,
    availabilities: Array,
    bandId: Number,
    isLeader: Boolean
  }

  connect() {
    this.loadCalendar()
  }

  async loadCalendar() {
    if (!window.FullCalendar) {
      // Load FullCalendar bundle (includes dayGrid, list, and other views)
      await this.loadScript("https://cdn.jsdelivr.net/npm/@fullcalendar/core@6.1.10/index.global.min.js")
      await this.loadScript("https://cdn.jsdelivr.net/npm/@fullcalendar/daygrid@6.1.10/index.global.min.js")
      await this.loadScript("https://cdn.jsdelivr.net/npm/@fullcalendar/list@6.1.10/index.global.min.js")
    }

    const events = this.buildEvents()

    this.calendar = new window.FullCalendar.Calendar(this.calendarTarget, {
      initialView: "dayGridMonth",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,listMonth"
      },
      events: events,
      eventClick: this.handleEventClick.bind(this),
      dateClick: this.handleDateClick.bind(this),
      eventDisplay: "block",
      height: "auto",
      dayMaxEvents: 3,
      moreLinkClick: "popover",
      eventDidMount: this.styleEvent.bind(this)
    })

    this.calendar.render()
  }

  buildEvents() {
    // This method transforms our Rails data (gigs, band events, availabilities)
    // into FullCalendar event objects. Each event has standard properties (id, title, start, end)
    // plus extendedProps for custom data we want to access later (like in the modal).
    const events = []

    // Add gigs (yellow)
    this.gigsValue.forEach(gig => {
      events.push({
        id: `gig-${gig.id}`,
        title: `🎤 ${gig.name}`,
        start: gig.date,
        url: gig.url,
        backgroundColor: "#fbbf24",
        borderColor: "#f59e0b",
        textColor: "#171717",
        // extendedProps stores custom data that FullCalendar preserves but doesn't use directly.
        // We retrieve this data later when the user clicks an event (see handleEventClick).
        extendedProps: {
          type: "gig",
          venue: gig.venue,
          startTime: gig.start_time,
          endTime: gig.end_time
        }
      })
    })

    // Add band events (different colors by type)
    const eventColors = {
      rehearsal: { bg: "#C8E938", border: "#9cbd2e", text: "#171717" },
      meeting: { bg: "#60a5fa", border: "#3b82f6", text: "#fff" },
      recording: { bg: "#E936AD", border: "#c42d93", text: "#fff" },
      other: { bg: "#8b5cf6", border: "#7c3aed", text: "#fff" }
    }

    this.bandEventsValue.forEach(event => {
      const colors = eventColors[event.event_type] || eventColors.other
      const icons = { rehearsal: "🎸", meeting: "📋", recording: "🎙️", other: "📌" }
      events.push({
        id: `event-${event.id}`,
        title: `${icons[event.event_type] || "📌"} ${event.title}`,
        start: event.date,
        backgroundColor: colors.bg,
        borderColor: colors.border,
        textColor: colors.text,
        extendedProps: {
          type: "band_event",
          eventType: event.event_type,
          location: event.location,
          description: event.description,
          startTime: event.start_time,
          endTime: event.end_time
        }
      })
    })

    // Add unavailabilities (red, shown as background events)
    // Supports date ranges: if end_date is set, the event spans multiple days
    this.availabilitiesValue.forEach(avail => {
      // FullCalendar uses exclusive end dates, so add 1 day to include the end_date
      let endDate = null
      if (avail.end_date) {
        const end = new Date(avail.end_date)
        end.setDate(end.getDate() + 1)
        endDate = end.toISOString().split('T')[0]
      }

      events.push({
        id: `avail-${avail.id}`,
        title: `❌ ${avail.musician_name} unavailable`,
        start: avail.start_date,
        end: endDate,  // If null, FullCalendar treats it as single-day event
        backgroundColor: "#ef4444",
        borderColor: "#dc2626",
        textColor: "#fff",
        display: "block",
        extendedProps: {
          type: "unavailability",
          musicianId: avail.musician_id,
          musicianName: avail.musician_name,
          reason: avail.reason,
          status: avail.status,
          startDate: avail.start_date,
          endDate: avail.end_date
        }
      })
    })

    return events
  }

  styleEvent(info) {
    info.el.style.cursor = "pointer"
    info.el.style.borderRadius = "4px"
    info.el.style.fontSize = "0.8rem"
    info.el.style.padding = "2px 4px"
  }

  handleEventClick(info) {
    info.jsEvent.preventDefault()

    // extendedProps is a FullCalendar feature that lets us attach custom data to events.
    // When we create events in buildEvents(), we store extra info (like venue, reason, etc.)
    // in the extendedProps object. Here we retrieve that custom data to display in the modal.
    const props = info.event.extendedProps

    if (props.type === "gig" && info.event.url) {
      window.location.href = info.event.url
      return
    }

    // Show modal with event details
    this.showEventModal(info.event)
  }

  handleDateClick(info) {
    if (!this.isLeaderValue) return

    // Show form to add new event
    this.showAddEventForm(info.dateStr)
  }

  showEventModal(event) {
    // props contains our custom event data stored in extendedProps during buildEvents().
    // This includes things like venue names, musician info, reasons, dates, etc.
    // We use props.type to determine which kind of event this is and display appropriate info.
    const props = event.extendedProps
    let content = ""

    if (props.type === "gig") {
      content = `
        <p><strong>Venue:</strong> ${props.venue || "TBA"}</p>
        <p><strong>Time:</strong> ${props.startTime || "TBA"} - ${props.endTime || "TBA"}</p>
      `
    } else if (props.type === "band_event") {
      content = `
        <p><strong>Type:</strong> ${props.eventType}</p>
        ${props.location ? `<p><strong>Location:</strong> ${props.location}</p>` : ""}
        ${props.startTime ? `<p><strong>Time:</strong> ${props.startTime} - ${props.endTime || "TBA"}</p>` : ""}
        ${props.description ? `<p><strong>Details:</strong> ${props.description}</p>` : ""}
      `
    } else if (props.type === "unavailability") {
      // Format date range: show "startDate to endDate" if range exists, otherwise just the single date
      const dateDisplay = props.endDate
        ? `${props.startDate} to ${props.endDate}`
        : props.startDate

      content = `
        <p><strong>Member:</strong> ${props.musicianName}</p>
        <p><strong>Dates:</strong> ${dateDisplay}</p>
        <p><strong>Status:</strong> ${props.status}</p>
        ${props.reason ? `<p><strong>Reason:</strong> ${props.reason}</p>` : ""}
      `
    }

    if (this.hasModalTarget) {
      this.modalTitleTarget.textContent = event.title.replace(/^[^\s]+\s/, "")
      this.modalBodyTarget.innerHTML = content
      this.modalTarget.style.display = "flex"
    }
  }

  showAddEventForm(dateStr = null) {
    if (this.hasEventFormTarget) {
      const dateInput = this.eventFormTarget.querySelector('[name="band_event[date]"]')
      if (dateStr) {
        dateInput.value = dateStr
      } else if (!dateInput.value) {
        // Default to today if no date provided and field is empty
        dateInput.value = new Date().toISOString().split('T')[0]
      }
      this.eventFormTarget.style.display = "block"
    }
  }

  closeModal() {
    if (this.hasModalTarget) {
      this.modalTarget.style.display = "none"
    }
  }

  closeEventForm() {
    if (this.hasEventFormTarget) {
      this.eventFormTarget.style.display = "none"
    }
  }

  loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = src
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy()
    }
  }
}
