import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="parallax"
export default class extends Controller {
  static targets = ["bannerText", "scrollContainer"]

  connect() {
    console.log("parallax is go.");
    this.handleScroll()
  }

  handleScroll() {
    const scrollPosition = window.scrollY || document.documentElement.scrollTop;

    const parallaxSpeed = 0.4;
    const translateY = scrollPosition * parallaxSpeed;

    this.bannerTextTarget.style.transform = `translate3d(0, ${translateY}px, 0)`;

    const fadeStart = 50;
    const fadeEnd = 300;

    let opacity = 1;

    if (scrollPosition > fadeStart) {
      opacity = 1 - (scrollPosition - fadeStart) / (fadeEnd - fadeStart);
    }

    this.bannerTextTarget.style.opacity = Math.max(0,opacity);

  }

}
