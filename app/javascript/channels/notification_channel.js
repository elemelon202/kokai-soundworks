import consumer from "./consumer"

// Only subscribe if user is logged in (check for notification bell)
document.addEventListener("DOMContentLoaded", () => {
  const notificationBell = document.getElementById("notification-bell")
  if (!notificationBell) return

  consumer.subscriptions.create("NotificationChannel", {
    connected() {
      console.log("Connected to NotificationChannel")
    },

    disconnected() {
      console.log("Disconnected from NotificationChannel")
    },

    received(data) {
      console.log("Notification received:", data)

      // Update the notification count badge
      updateNotificationCount(data.unread_count)

      // Add the notification to the dropdown
      addNotificationToDropdown(data)

      // Show a toast notification
      showToastNotification(data)
    }
  })
})

function updateNotificationCount(count) {
  const badge = document.getElementById("notification-count")
  if (badge) {
    if (count > 0) {
      badge.textContent = count > 99 ? "99+" : count
      badge.style.display = "flex"
    } else {
      badge.style.display = "none"
    }
  }
}

function addNotificationToDropdown(data) {
  const list = document.getElementById("notification-list")
  const emptyState = document.getElementById("notification-empty")

  if (!list) return

  // Hide empty state if showing
  if (emptyState) {
    emptyState.style.display = "none"
  }

  // Create notification item
  const item = document.createElement("a")
  item.href = data.path || "#"
  item.className = "notification-item unread"
  item.dataset.notificationId = data.id

  item.innerHTML = `
    <div class="notification-icon">
      <i class="${data.icon_class}"></i>
    </div>
    <div class="notification-content">
      <p class="notification-message">${data.message}</p>
      <span class="notification-time">Just now</span>
    </div>
  `

  // Add to top of list
  list.insertBefore(item, list.firstChild)

  // Remove old notifications if more than 20
  const items = list.querySelectorAll(".notification-item")
  if (items.length > 20) {
    items[items.length - 1].remove()
  }
}

function showToastNotification(data) {
  // Create toast container if it doesn't exist
  let toastContainer = document.getElementById("notification-toast-container")
  if (!toastContainer) {
    toastContainer = document.createElement("div")
    toastContainer.id = "notification-toast-container"
    document.body.appendChild(toastContainer)
  }

  // Create toast
  const toast = document.createElement("div")
  toast.className = "notification-toast"
  toast.innerHTML = `
    <div class="toast-icon">
      <i class="${data.icon_class}"></i>
    </div>
    <div class="toast-content">
      <p>${data.message}</p>
    </div>
    <button class="toast-close" onclick="this.parentElement.remove()">
      <i class="fa-solid fa-times"></i>
    </button>
  `

  toastContainer.appendChild(toast)

  // Auto-remove after 5 seconds
  setTimeout(() => {
    toast.classList.add("fade-out")
    setTimeout(() => toast.remove(), 300)
  }, 5000)
}
