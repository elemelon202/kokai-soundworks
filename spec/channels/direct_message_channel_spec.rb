require 'rails_helper'

RSpec.describe DirectMessageChannel, type: :channel do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:chat) { create(:chat, :direct_message, :with_participants, participants: [user, other_user]) }

  before do
    stub_connection current_user: user
  end

  describe '#subscribed' do
    it 'successfully subscribes to a chat channel' do
      subscribe(chat_id: chat.id)
      expect(subscription).to be_confirmed
    end

    it 'streams from the correct chat channel' do
      subscribe(chat_id: chat.id)
      expect(subscription).to have_stream_from("chat_#{chat.id}")
    end

    it 'rejects subscription for non-existent chat' do
      expect {
        subscribe(chat_id: 99999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#unsubscribed' do
    it 'stops all streams when unsubscribed' do
      subscribe(chat_id: chat.id)
      expect(subscription).to have_stream_from("chat_#{chat.id}")

      subscription.unsubscribe_from_channel
      expect(subscription).not_to have_streams
    end
  end
end
