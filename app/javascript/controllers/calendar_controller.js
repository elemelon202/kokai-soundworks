import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    events: Array
  }

  connect() {
    this.loadCalendar()
  }

  async loadCalendar() {
    // Load FullCalendar from CDN
    if (!window.FullCalendar) {
      await this.loadScript("https://cdn.jsdelivr.net/npm/fullcalendar@6.1.19/index.global.min.js")
    }

    this.calendar = new window.FullCalendar.Calendar(this.element, {
      initialView: "dayGridMonth",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: ""
      },
      events: this.eventsValue,
      eventClick: this.handleEventClick.bind(this),
      eventDisplay: "block",
      height: "auto",
      eventColor: "#C8E938",
      eventTextColor: "#171717",
      dayMaxEvents: 3,
      moreLinkClick: "popover"
    })

    this.calendar.render()
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

  handleEventClick(info) {
    if (info.event.url) {
      info.jsEvent.preventDefault()
      window.location.href = info.event.url
    }
  }
}
