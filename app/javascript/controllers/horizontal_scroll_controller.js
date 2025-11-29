import { Controller } from "@hotwired/stimulus"

// Converts vertical scroll wheel to horizontal scrolling with infinite scroll
export default class extends Controller {
  static targets = ["shelf", "pageIndicator", "pageInfo"]
  static values = {
    currentPage: Number,
    totalPages: Number,
    itemsPerPage: Number,
    baseUrl: String,
    query: String,
    instrument: Array,
    location: Array
  }

  connect() {
    this.shelfTarget.addEventListener("wheel", this.handleWheel.bind(this), { passive: false })
    this.shelfTarget.addEventListener("scroll", this.handleScroll.bind(this))
    this.loading = false
    this.loadedPages = new Set([this.currentPageValue])
    this.updatePageIndicator()
  }

  disconnect() {
    this.shelfTarget.removeEventListener("wheel", this.handleWheel.bind(this))
    this.shelfTarget.removeEventListener("scroll", this.handleScroll.bind(this))
  }

  handleWheel(event) {
    if (Math.abs(event.deltaY) > Math.abs(event.deltaX)) {
      event.preventDefault()
      this.shelfTarget.scrollLeft += event.deltaY
    }
  }

  handleScroll() {
    this.updatePageIndicator()
    this.checkForMoreContent()
  }

  updatePageIndicator() {
    const shelf = this.shelfTarget
    const items = shelf.querySelectorAll('.record-item')
    if (items.length === 0) return

    const shelfRect = shelf.getBoundingClientRect()
    const shelfCenter = shelfRect.left + shelfRect.width / 2

    let closestItem = null
    let closestDistance = Infinity

    items.forEach(item => {
      const itemRect = item.getBoundingClientRect()
      const itemCenter = itemRect.left + itemRect.width / 2
      const distance = Math.abs(itemCenter - shelfCenter)

      if (distance < closestDistance) {
        closestDistance = distance
        closestItem = item
      }
    })

    if (closestItem) {
      const itemPage = parseInt(closestItem.dataset.page) || 1
      if (itemPage !== this.displayedPage) {
        this.displayedPage = itemPage
        this.highlightCurrentPage(itemPage)
        this.updatePageInfoText(itemPage)
      }
    }
  }

  highlightCurrentPage(page) {
    if (!this.hasPageIndicatorTarget) return

    const indicators = this.pageIndicatorTarget.querySelectorAll('[data-page-number]')
    indicators.forEach(indicator => {
      const pageNum = parseInt(indicator.dataset.pageNumber)
      if (pageNum === page) {
        indicator.style.background = '#C8E938'
        indicator.style.color = '#000'
        indicator.style.fontWeight = '600'
      } else {
        indicator.style.background = '#2a2a2a'
        indicator.style.color = '#fff'
        indicator.style.fontWeight = 'normal'
      }
    })
  }

  updatePageInfoText(page) {
    if (!this.hasPageInfoTarget) return

    const start = (page - 1) * this.itemsPerPageValue + 1
    const end = Math.min(page * this.itemsPerPageValue, this.totalCountValue || (this.totalPagesValue * this.itemsPerPageValue))
    const total = this.totalCountValue || (this.totalPagesValue * this.itemsPerPageValue)

    this.pageInfoTarget.textContent = `Viewing page ${page} of ${this.totalPagesValue}`
  }

  checkForMoreContent() {
    const shelf = this.shelfTarget
    const scrollRight = shelf.scrollWidth - shelf.scrollLeft - shelf.clientWidth

    // Load next page when near the end
    if (scrollRight < 500 && !this.loading) {
      const nextPage = Math.max(...this.loadedPages) + 1
      if (nextPage <= this.totalPagesValue) {
        this.loadPage(nextPage, 'append')
      }
    }

    // Load previous page when near the start
    if (shelf.scrollLeft < 500 && !this.loading) {
      const prevPage = Math.min(...this.loadedPages) - 1
      if (prevPage >= 1) {
        this.loadPage(prevPage, 'prepend')
      }
    }
  }

  async loadPage(page, position) {
    if (this.loadedPages.has(page) || this.loading) return

    this.loading = true

    const params = new URLSearchParams()
    params.set('page', page)
    if (this.queryValue) params.set('query', this.queryValue)
    if (this.instrumentValue?.length) {
      this.instrumentValue.forEach(i => params.append('instrument[]', i))
    }
    if (this.locationValue?.length) {
      this.locationValue.forEach(l => params.append('location[]', l))
    }

    try {
      const response = await fetch(`${this.baseUrlValue}?${params.toString()}`, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const newItems = doc.querySelectorAll('.record-item')

        if (newItems.length > 0) {
          const shelf = this.shelfTarget
          const previousScrollLeft = shelf.scrollLeft
          const previousScrollWidth = shelf.scrollWidth

          if (position === 'prepend') {
            const fragment = document.createDocumentFragment()
            newItems.forEach(item => fragment.appendChild(item.cloneNode(true)))
            shelf.insertBefore(fragment, shelf.firstChild)

            // Maintain scroll position when prepending
            const newScrollWidth = shelf.scrollWidth
            shelf.scrollLeft = previousScrollLeft + (newScrollWidth - previousScrollWidth)
          } else {
            newItems.forEach(item => shelf.appendChild(item.cloneNode(true)))
          }

          this.loadedPages.add(page)
        }
      }
    } catch (error) {
      console.error('Error loading page:', error)
    }

    this.loading = false
  }

  goToPage(event) {
    event.preventDefault()
    const page = parseInt(event.currentTarget.dataset.pageNumber)
    if (!page) return

    // Find the first item of that page and scroll to it
    const targetItem = this.shelfTarget.querySelector(`.record-item[data-page="${page}"]`)
    if (targetItem) {
      targetItem.scrollIntoView({ behavior: 'smooth', inline: 'start', block: 'nearest' })
    } else if (!this.loadedPages.has(page)) {
      // Page not loaded yet, load it first
      this.loadPage(page, page > this.currentPageValue ? 'append' : 'prepend').then(() => {
        setTimeout(() => {
          const item = this.shelfTarget.querySelector(`.record-item[data-page="${page}"]`)
          if (item) {
            item.scrollIntoView({ behavior: 'smooth', inline: 'start', block: 'nearest' })
          }
        }, 100)
      })
    }
  }
}
