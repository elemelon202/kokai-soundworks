import { Controller } from "@hotwired/stimulus"

/**
 * Mobile Navigation Controller
 *
 * Creates a fixed bottom tab bar for mobile devices that allows quick navigation
 * between dashboard sections. Only active on screens <= 768px.
 *
 * Usage:
 *   <div data-controller="mobile-nav">
 *     <section id="section-home" data-mobile-nav-target="section" data-section="home">...</section>
 *     <section id="section-profile" data-mobile-nav-target="section" data-section="profile">...</section>
 *
 *     <nav class="mobile-bottom-nav" data-mobile-nav-target="nav">
 *       <button data-mobile-nav-target="tab" data-section="home" data-action="click->mobile-nav#navigate">
 *         <i class="fa-solid fa-home"></i>
 *         <span>Home</span>
 *       </button>
 *     </nav>
 *   </div>
 */
export default class extends Controller {
  static targets = ["nav", "tab", "section"]

  connect() {
    this.setupIntersectionObserver()
    this.checkMobile()
    window.addEventListener("resize", this.checkMobile.bind(this))

    // Set initial active tab
    this.setActiveTab("home")
  }

  disconnect() {
    window.removeEventListener("resize", this.checkMobile.bind(this))
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  checkMobile() {
    this.isMobile = window.innerWidth <= 768
  }

  /**
   * Navigate to a section when tab is tapped
   */
  navigate(event) {
    event.preventDefault()
    const sectionName = event.currentTarget.dataset.section
    const section = this.sectionTargets.find(s => s.dataset.section === sectionName)

    if (section) {
      // Calculate offset for sticky navbar (approximately 60px)
      const navbarOffset = 70
      const sectionTop = section.getBoundingClientRect().top + window.pageYOffset - navbarOffset

      window.scrollTo({
        top: sectionTop,
        behavior: "smooth"
      })

      // Update active tab immediately for responsiveness
      this.setActiveTab(sectionName)

      // Add a pulse animation to the section header
      this.pulseSection(section)
    }
  }

  /**
   * Set the active tab in the bottom nav
   */
  setActiveTab(sectionName) {
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.section === sectionName
      tab.classList.toggle("active", isActive)
      tab.setAttribute("aria-selected", isActive)
    })
  }

  /**
   * Add a brief pulse animation to indicate the section
   */
  pulseSection(section) {
    const header = section.querySelector(".musician-card-header, .section-header, h3, h4")
    if (header) {
      header.classList.add("mobile-nav-pulse")
      setTimeout(() => {
        header.classList.remove("mobile-nav-pulse")
      }, 600)
    }
  }

  /**
   * Setup IntersectionObserver to track which section is in view
   */
  setupIntersectionObserver() {
    const options = {
      root: null,
      rootMargin: "-20% 0px -60% 0px", // Trigger when section is in upper portion of viewport
      threshold: 0
    }

    this.observer = new IntersectionObserver((entries) => {
      if (!this.isMobile) return

      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const sectionName = entry.target.dataset.section
          if (sectionName) {
            this.setActiveTab(sectionName)
          }
        }
      })
    }, options)

    // Observe all sections
    this.sectionTargets.forEach(section => {
      this.observer.observe(section)
    })
  }
}
