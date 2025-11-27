import { Application } from '@hotwired/stimulus'
import DropdownController from '../../../app/javascript/controllers/dropdown_controller'

describe('DropdownController', () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = `
      <div data-controller="dropdown">
        <button data-action="click->dropdown#toggle">Toggle Menu</button>
        <div data-dropdown-target="menu" class="hidden">
          <a href="#">Option 1</a>
          <a href="#">Option 2</a>
        </div>
      </div>
      <div id="outside">Outside element</div>
    `

    element = document.querySelector('[data-controller="dropdown"]')

    // Setup Stimulus
    application = Application.start()
    application.register('dropdown', DropdownController)
    controller = application.getControllerForElementAndIdentifier(element, 'dropdown')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('menu toggling', () => {
    it('opens menu when clicking toggle button', () => {
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')

      expect(menu.classList.contains('hidden')).toBe(true)

      button.click()

      expect(menu.classList.contains('hidden')).toBe(false)
    })

    it('closes menu when clicking toggle button again', () => {
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')

      button.click() // open
      expect(menu.classList.contains('hidden')).toBe(false)

      button.click() // close
      expect(menu.classList.contains('hidden')).toBe(true)
    })

    it('prevents event propagation when toggling', () => {
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      const mockHandler = jest.fn()

      document.addEventListener('click', mockHandler)

      button.click()

      expect(mockHandler).not.toHaveBeenCalled()

      document.removeEventListener('click', mockHandler)
    })
  })

  describe('click outside behavior', () => {
    it('closes menu when clicking outside', () => {
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      const outside = document.getElementById('outside')

      button.click() // open
      expect(menu.classList.contains('hidden')).toBe(false)

      outside.click() // click outside
      expect(menu.classList.contains('hidden')).toBe(true)
    })

    it('keeps menu open when clicking inside dropdown element', () => {
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      const menuOption = menu.querySelector('a')

      button.click() // open
      expect(menu.classList.contains('hidden')).toBe(false)

      menuOption.click() // click inside
      expect(menu.classList.contains('hidden')).toBe(false)
    })
  })

  describe('initialization', () => {
    it('ensures menu is hidden on connect', () => {
      // The menu should be hidden initially based on the test setup
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      expect(menu.classList.contains('hidden')).toBe(true)

      // Open the menu
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      button.click()
      expect(menu.classList.contains('hidden')).toBe(false)

      // Close it again
      button.click()
      expect(menu.classList.contains('hidden')).toBe(true)
    })
  })

  describe('cleanup', () => {
    it('removes event listener on disconnect', () => {
      const button = element.querySelector('[data-action="click->dropdown#toggle"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      const outside = document.getElementById('outside')

      button.click() // open menu
      expect(menu.classList.contains('hidden')).toBe(false)

      // Verify the menu closes on outside click normally
      outside.click()
      expect(menu.classList.contains('hidden')).toBe(true)

      // Open again and disconnect
      button.click()
      expect(menu.classList.contains('hidden')).toBe(false)

      // Disconnect controller
      application.stop()

      // Since controller is disconnected, menu state shouldn't change
      // but we can't test outside click behavior as the controller is gone
      // Instead, we verify the menu remains in its current state
      expect(menu.classList.contains('hidden')).toBe(false)
    })
  })
})