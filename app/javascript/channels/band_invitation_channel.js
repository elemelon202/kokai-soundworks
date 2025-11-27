import consumer from "channels/consumer"

let currentSubscription = null;

document.addEventListener("turbo:load", () => {
  const pendingInvitationsContainer = document.getElementById("pending_invitations_list");

  if (!pendingInvitationsContainer) return;

  const bandId = pendingInvitationsContainer.dataset.bandId;

  if (!bandId) return;

  // Unsubscribe from previous subscription if exists
  if (currentSubscription) {
    currentSubscription.unsubscribe();
  }

  // Subscribe to band invitation updates
  currentSubscription = consumer.subscriptions.create(
    { channel: "BandInvitationChannel", band_id: bandId },
    {
      connected() {
        console.log("Connected to BandInvitationChannel for band:", bandId);
      },

      disconnected() {
        console.log("Disconnected from BandInvitationChannel");
      },

      received(data) {
        if (data.type === "invitation_updated") {
          // Update the pending invitations list
          const container = document.getElementById("pending_invitations_list");
          if (container) {
            container.innerHTML = data.html;
          }

          // Update the member count card if present
          const memberCountCard = document.querySelector(".card h2 + *");
          if (memberCountCard && data.member_count !== undefined) {
            const memberCard = document.querySelector(".card:nth-child(2)");
            if (memberCard) {
              const countElement = memberCard.querySelector("h2");
              if (countElement && countElement.textContent === "Band Members") {
                const countNode = countElement.nextSibling;
                if (countNode) {
                  countNode.textContent = data.member_count;
                }
              }
            }
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
