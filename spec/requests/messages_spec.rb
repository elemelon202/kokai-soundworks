require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:chat) { create(:chat, :direct_message, :with_participants, participants: [user, other_user]) }

  describe "POST /chats/:chat_id/messages" do
    context "when not logged in" do
      it "redirects to login" do
        post chat_messages_path(chat), params: { message: { content: "Hello" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as a participant" do
      before { sign_in user }

      it "creates a new message" do
        expect {
          post chat_messages_path(chat), params: { message: { content: "Hello" } }
        }.to change(Message, :count).by(1)
      end

      it "associates the message with the current user" do
        post chat_messages_path(chat), params: { message: { content: "Hello" } }
        expect(Message.last.user).to eq(user)
      end

      it "associates the message with the chat" do
        post chat_messages_path(chat), params: { message: { content: "Hello" } }
        expect(Message.last.chat).to eq(chat)
      end
    end
  end

  describe "DELETE /chats/:chat_id/messages/:id" do
    let!(:message) { create(:message, chat: chat, user: user) }

    context "when not logged in" do
      it "redirects to login" do
        delete chat_message_path(chat, message)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as message author" do
      before { sign_in user }

      it "destroys the message" do
        expect {
          delete chat_message_path(chat, message)
        }.to change(Message, :count).by(-1)
      end
    end
  end
end
