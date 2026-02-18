import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { sentAt: Number }
  static targets = ["button", "countdown"]

  connect() {
    this.tick()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  tick() {
    const remaining = 60 - (Math.floor(Date.now() / 1000) - this.sentAtValue)

    if (remaining > 0) {
      this.buttonTarget.disabled = true
      this.countdownTarget.textContent = `${remaining}s`
      this.timer = setTimeout(() => this.tick(), 1000)
    } else {
      this.buttonTarget.disabled = false
      this.countdownTarget.textContent = ""
    }
  }
}
