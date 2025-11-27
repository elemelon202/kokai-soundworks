require 'rails_helper'

RSpec.describe "DirectMessages", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /direct_messages" do
    context "when not logged in" do
      it "redirects to login" do
        get direct_messages_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "returns a successful response" do
        get direct_messages_path
        expect(response).to have_http_status(:success)
      end

      it "displays the user's DM chats" do
        chat = Chat.between(user, other_user)
        get direct_messages_path
        expect(response.body).to include(other_user.username)
      end
    end
  end

  describe "GET /direct_messages/:id" do
    let(:chat) { Chat.between(user, other_user) }

    context "when not logged in" do
      it "redirects to login" do
        get direct_message_path(chat)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as a participant" do
      before { sign_in user }

      it "returns a successful response" do
        get direct_message_path(chat)
        expect(response).to have_http_status(:success)
      end

      it "marks messages as read" do
        message = create(:message, chat: chat, user: other_user)
        message_read = create(:message_read, message: message, user: user, read: false)

        get direct_message_path(chat)
        expect(message_read.reload.read).to be true
      end
    end

    context "when logged in as non-participant" do
      let(:third_user) { create(:user) }

      before { sign_in third_user }

      it "redirects with unauthorized message" do
        get direct_message_path(chat)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /direct_messages/create_or_show" do
    context "when not logged in" do
      it "redirects to login" do
        post create_or_show_direct_messages_path, params: { recipient_id: other_user.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "creates a new DM chat if one doesn't exist" do
        expect {
          post create_or_show_direct_messages_path, params: { recipient_id: other_user.id }
        }.to change(Chat, :count).by(1)
      end

      it "redirects to the existing chat if one exists" do
        existing_chat = Chat.between(user, other_user)
        post create_or_show_direct_messages_path, params: { recipient_id: other_user.id }
        expect(response).to redirect_to(direct_message_path(existing_chat))
      end
    end
  end
end
