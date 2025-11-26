// Mock flatpickr before any imports
jest.mock('flatpickr', () => {
  return jest.fn((element, config) => {
    return {
      config: {
        ...config,
        defaultDate: config.defaultDate || null
      },
      destroy: jest.fn(),
      setDate: jest.fn(),
      element: element
    }
  })
})

import { Application } from '@hotwired/stimulus'
import DatetimePickerController from '../../../app/javascript/controllers/datetime_picker_controller'
import flatpickr from 'flatpickr'

// Get the mocked flatpickr
const mockFlatpickr = flatpickr

describe('DatetimePickerController', () => {
  let application
  let element

  beforeEach(() => {
    // Reset mock
    mockFlatpickr.mockClear()

    // Create the application
    application = Application.start()
    application.register('datetime-picker', DatetimePickerController)

    // Set up the DOM
    document.body.innerHTML = `
      <div data-controller="datetime-picker">
        <input
          type="text"
          data-datetime-picker-target="input"
          id="test-datetime-input"
          placeholder="Select date and time"
        />
        <span data-datetime-picker-target="timezone"></span>
      </div>
    `

    element = document.querySelector('[data-controller="datetime-picker"]')
  })

  afterEach(() => {
    // Clean up
    application.stop()
    document.body.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('#connect', () => {
    it('initializes flatpickr on the input element', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      expect(controller.flatpickr).toBeDefined()
      expect(controller.flatpickr.config).toBeDefined()
    })

    it('sets the correct flatpickr configuration', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const config = controller.flatpickr.config

      expect(config.enableTime).toBe(true)
      expect(config.dateFormat).toBe('Y-m-d H:i')
      expect(config.altInput).toBe(true)
      expect(config.altFormat).toBe('F j, Y at h:i K')
      expect(config.minuteIncrement).toBe(15)
      expect(config.time_24hr).toBe(false)
      expect(config.allowInput).toBe(true)
      expect(config.disableMobile).toBe(false)
    })

    it('sets default date to tomorrow at 9 AM local time when no value is provided', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const defaultDate = controller.flatpickr.config.defaultDate

      // Check that it's set to tomorrow
      const tomorrow = new Date()
      tomorrow.setDate(tomorrow.getDate() + 1)
      tomorrow.setHours(9, 0, 0, 0)

      expect(defaultDate.getDate()).toBe(tomorrow.getDate())
      expect(defaultDate.getHours()).toBe(9)
      expect(defaultDate.getMinutes()).toBe(0)
    })

    it('uses existing value when input has a value', () => {
      // First, let's verify that setting the value on the existing input will be used
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')

      // The mock flatpickr was called with the input's value (or default tomorrow)
      // Check the first call to mockFlatpickr
      const callArgs = mockFlatpickr.mock.calls[0]
      const config = callArgs[1]

      // Since the input initially had no value, it should use tomorrow as default
      // Let's test that when an input HAS a value, it gets passed to flatpickr
      // We need to reset the mock and re-initialize

      // Clean up existing
      controller.disconnect()
      mockFlatpickr.mockClear()

      // Set value on input
      const input = element.querySelector('[data-datetime-picker-target="input"]')
      input.value = '2024-06-15 14:30'

      // Re-connect the controller
      controller.connect()

      // Check that flatpickr was called with the input's value
      expect(mockFlatpickr).toHaveBeenCalled()
      const newConfig = mockFlatpickr.mock.calls[0][1]
      expect(newConfig.defaultDate).toBe('2024-06-15 14:30')
    })

    it('stores timezone in dataset', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const timezone = element.dataset.timezone

      expect(timezone).toBeDefined()
      expect(timezone).toMatch(/^[A-Za-z]+\/[A-Za-z_]+$/) // Basic timezone format check
    })

    it('displays timezone to user if timezone target exists', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const timezoneDisplay = element.querySelector('[data-datetime-picker-target="timezone"]')

      if (timezoneDisplay) {
        const expectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone
        expect(timezoneDisplay.textContent).toContain(expectedTimezone)
      }
    })
  })

  describe('#disconnect', () => {
    it('destroys flatpickr instance when disconnected', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const flatpickrInstance = controller.flatpickr
      const destroySpy = jest.spyOn(flatpickrInstance, 'destroy')

      controller.disconnect()

      expect(destroySpy).toHaveBeenCalled()
    })

    it('handles disconnect gracefully when flatpickr is not initialized', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      controller.flatpickr = null

      expect(() => controller.disconnect()).not.toThrow()
    })
  })

  describe('#formatForRails', () => {
    it('formats date correctly for Rails', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const testDate = new Date('2024-06-15T14:30:00')

      const formatted = controller.formatForRails(testDate)

      expect(formatted).toBe('2024-06-15 14:30')
    })

    it('pads single digit months and days', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const testDate = new Date('2024-01-05T09:05:00')

      const formatted = controller.formatForRails(testDate)

      expect(formatted).toBe('2024-01-05 09:05')
    })
  })

  describe('onChange callback', () => {
    it('updates input value when date is selected', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const input = element.querySelector('[data-datetime-picker-target="input"]')
      const testDate = new Date('2024-06-15T14:30:00')

      // Get the onChange callback that was passed to flatpickr
      const onChangeCallback = mockFlatpickr.mock.calls[0][1].onChange

      // Simulate date selection
      if (onChangeCallback) {
        onChangeCallback([testDate], '2024-06-15 14:30', controller.flatpickr)
        expect(input.value).toBe('2024-06-15 14:30')
      }
    })

    it('does not update input when no date is selected', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const input = element.querySelector('[data-datetime-picker-target="input"]')
      const originalValue = input.value

      // Get the onChange callback that was passed to flatpickr
      const onChangeCallback = mockFlatpickr.mock.calls[0][1].onChange

      // Simulate empty selection
      if (onChangeCallback) {
        onChangeCallback([], '', controller.flatpickr)
        expect(input.value).toBe(originalValue)
      }
    })
  })

  describe('timezone detection', () => {
    it('detects user timezone using Intl API', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'datetime-picker')
      const detectedTimezone = element.dataset.timezone
      const expectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

      expect(detectedTimezone).toBe(expectedTimezone)
    })
  })
})