import consumer from "./consumer"

document.addEventListener("DOMContentLoaded", () => {
  const messagesBtn = document.getElementById("messages-notification-btn")
  if (!messagesBtn) return

  consumer.subscriptions.create("MessagesNotificationChannel", {
    connected() {
      console.log("Connected to MessagesNotificationChannel")
    },

    disconnected() {
      console.log("Disconnected from MessagesNotificationChannel")
    },

    received(data) {
      console.log("Message notification received:", data)

      // Update the message count badge
      updateMessageCount(data.unread_count)

      // Show toast if new message
      if (data.show_toast) {
        showMessageToast(data)
      }
    }
  })
})

function updateMessageCount(count) {
  const badge = document.getElementById("messages-count")
  if (badge) {
    if (count > 0) {
      badge.textContent = count > 99 ? "99+" : count
      badge.style.display = "flex"

      // Add pulse animation
      badge.classList.add("pulse")
      setTimeout(() => badge.classList.remove("pulse"), 1000)
    } else {
      badge.style.display = "none"
    }
  }
}

function showMessageToast(data) {
  // Create toast container if it doesn't exist
  let toastContainer = document.getElementById("notification-toast-container")
  if (!toastContainer) {
    toastContainer = document.createElement("div")
    toastContainer.id = "notification-toast-container"
    document.body.appendChild(toastContainer)
  }

  // Create toast
  const toast = document.createElement("div")
  toast.className = "notification-toast message-toast"
  toast.innerHTML = `
    <div class="toast-icon">
      <i class="fa-solid fa-comment"></i>
    </div>
    <div class="toast-content">
      <p><strong>${data.sender_name}</strong></p>
      <p class="toast-preview">${data.message_preview}</p>
    </div>
    <button class="toast-close" onclick="this.parentElement.remove()">
      <i class="fa-solid fa-times"></i>
    </button>
  `

  // Make toast clickable to go to messages
  toast.style.cursor = "pointer"
  toast.addEventListener("click", (e) => {
    if (!e.target.closest(".toast-close")) {
      window.location.href = data.chat_path
    }
  })

  toastContainer.appendChild(toast)

  // Auto-remove after 5 seconds
  setTimeout(() => {
    toast.classList.add("fade-out")
    setTimeout(() => toast.remove(), 300)
  }, 5000)
}
