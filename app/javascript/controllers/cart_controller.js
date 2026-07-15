// app/javascript/controllers/cart_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["addButton", "checkoutButton", "badge", "badgeCount"];

  add(event) {
    const btn = event.currentTarget;
    const originalText = btn.textContent.trim();
    const originalClasses = [...btn.classList];

    // Button aufleuchten
    btn.textContent = "✓";
    btn.classList.add("bg-green-600", "scale-110");
    btn.classList.remove("bg-blue-600", "bg-gray-700");

    // Badge animieren
    if (this.hasBadgeTarget) {
      this.badgeTarget.classList.add("animate-bounce");
      setTimeout(() => {
        this.badgeTarget.classList.remove("animate-bounce");
      }, 800);
    }

    // Button zurücksetzen
    setTimeout(() => {
      btn.textContent = originalText;
      btn.classList.remove("bg-green-600", "scale-110");
      btn.classList.add("bg-blue-600");
    }, 600);
  }

  checkout(event) {
    const btn = event.currentTarget;

    btn.textContent = "⏳ Wird gebucht...";
    btn.disabled = true;
    btn.classList.add("opacity-75", "cursor-not-allowed");
    btn.classList.remove("hover:bg-green-500", "active:scale-95");
  }

  remove(event) {
    const btn = event.currentTarget;
    const row = btn.closest("tr") || btn.closest("[data-cart-row]");

    if (row) {
      row.classList.add("opacity-0", "scale-95");
      row.style.transition = "all 0.2s ease-out";
    }
  }
}
