import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['menu']

  connect() {
    this.close()
    document.addEventListener('click', this.closeOnClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnClickOutside.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains('hidden')) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden')
  }

  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}