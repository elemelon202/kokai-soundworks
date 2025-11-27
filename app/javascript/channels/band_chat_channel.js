import consumer from "channels/consumer"

let currentSubscription = null;

document.addEventListener("turbo:load", () => {
  const bandChat = document.getElementById("band-chat");

  if (!bandChat) return;

  const chatId = bandChat.dataset.chatId;
  const currentUserId = parseInt(bandChat.dataset.currentUserId);

  if (!chatId) return;

  // Unsubscribe from previous chat if exists
  if (currentSubscription) {
    currentSubscription.unsubscribe();
  }

  // Subscribe to the band chat
  currentSubscription = consumer.subscriptions.create(
    { channel: "BandChatChannel", chat_id: chatId },
    {
      connected() {
        console.log("Connected to BandChatChannel for chat:", chatId);
      },

      disconnected() {
        console.log("Disconnected from BandChatChannel");
      },

      received(data) {
        // Only append message if we didn't send it (sender sees it via form response)
        if (data.sender_id !== currentUserId) {
          const messagesContainer = document.getElementById("band-messages");
          if (messagesContainer) {
            messagesContainer.insertAdjacentHTML("beforeend", data.html);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
          }
        }
      }
    }
  );

  // Handle form submission via AJAX
  const form = document.getElementById("band-message-form");
  if (form) {
    const formChatId = form.dataset.chatId;

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      e.stopPropagation();

      const input = document.getElementById("band-message-input");
      const content = input.value.trim();

      if (!content) return;

      try {
        const formData = new FormData();
        formData.append("message[content]", content);

        const response = await fetch(`/chats/${formChatId}/messages.json`, {
          method: "POST",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
          },
          body: formData
        });

        if (response.ok) {
          const data = await response.json();
          // Append sender's message to the chat
          const messagesContainer = document.getElementById("band-messages");
          if (messagesContainer && data.html) {
            messagesContainer.insertAdjacentHTML("beforeend", data.html);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
          }
          input.value = "";
        } else {
          const errorData = await response.text();
          console.error("Failed to send message:", response.status, errorData);
        }
      } catch (error) {
        console.error("Error sending message:", error);
      }

      return false;
    });
  }
});

// Clean up when leaving the page
document.addEventListener("turbo:before-visit", () => {
  if (currentSubscription) {
    currentSubscription.unsubscribe();
    currentSubscription = null;
  }
});
