import consumer from "channels/consumer"

// Store the subscription globally so we can unsubscribe
let currentSubscription = null;

document.addEventListener("turbo:load", () => {
  const messagesContainer = document.getElementById("messages");

  if (!messagesContainer) return;

  const chatId = messagesContainer.dataset.chatId;
  const currentUserId = parseInt(messagesContainer.dataset.currentUserId);

  if (!chatId) return;

  // Unsubscribe from previous chat if exists
  if (currentSubscription) {
    currentSubscription.unsubscribe();
  }

  // Subscribe to the new chat
  currentSubscription = consumer.subscriptions.create(
    { channel: "DirectMessageChannel", chat_id: chatId },
    {
      connected() {
        console.log("Connected to DirectMessageChannel for chat:", chatId);
      },

      disconnected() {
        console.log("Disconnected from DirectMessageChannel");
      },

      received(data) {
        // Only append message if we're the recipient (not the sender)
        // The sender already sees the message via Turbo Stream
        if (data.sender_id !== currentUserId && data.user_id === currentUserId) {
          const messagesContainer = document.getElementById("messages");
          if (messagesContainer) {
            messagesContainer.insertAdjacentHTML("beforeend", data.html);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
          }
        }
      }
    }
  );
});

// Clean up when leaving the page
document.addEventListener("turbo:before-visit", () => {
  if (currentSubscription) {
    currentSubscription.unsubscribe();
    currentSubscription = null;
  }
});
