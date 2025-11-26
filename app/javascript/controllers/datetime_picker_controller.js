import { Controller } from '@hotwired/stimulus'
import flatpickr from 'flatpickr'

export default class extends Controller {
  static targets = ['input', 'timezone']

  connect() {
    // Get the user's timezone
    const userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

    // Display timezone to user if target exists
    if (this.hasTimezoneTarget) {
      this.timezoneTarget.textContent = `(${userTimezone})`
    }

    // Set default date to tomorrow at 9 AM local time
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    tomorrow.setHours(9, 0, 0, 0) // Set to 9:00 AM local time

    // Configure Flatpickr with better UX
    this.flatpickr = flatpickr(this.inputTarget, {
      enableTime: true,
      dateFormat: 'Y-m-d H:i',
      altInput: true,
      altFormat: 'F j, Y at h:i K', // e.g., "January 1, 2024 at 9:00 AM"
      defaultDate: this.inputTarget.value || tomorrow, // Tomorrow at 9 AM local time
      minuteIncrement: 15, // 15-minute intervals
      time_24hr: false, // Use 12-hour format with AM/PM

      // Mobile-friendly
      disableMobile: false,

      // Allow manual input
      allowInput: true,

      // When date is selected, ensure we maintain timezone context
      onChange: (selectedDates, _dateStr, _instance) => {
        // Store the selected date in ISO format for the server
        if (selectedDates.length > 0) {
          const localDate = selectedDates[0]
          // This will be sent to the server
          this.inputTarget.value = this.formatForRails(localDate)
        }
      }
    })

    // Store timezone in a hidden field or data attribute for server processing
    this.element.dataset.timezone = userTimezone
  }

  disconnect() {
    if (this.flatpickr) {
      this.flatpickr.destroy()
    }
  }

  formatForRails(date) {
    // Format as YYYY-MM-DD HH:MM for Rails datetime_field compatibility
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')

    return `${year}-${month}-${day} ${hours}:${minutes}`
  }
}