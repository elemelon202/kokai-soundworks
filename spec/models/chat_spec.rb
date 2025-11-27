require 'rails_helper'

RSpec.describe Chat, type: :model do
  describe 'associations' do
    it { should belong_to(:band).optional }
    it { should have_many(:messages).dependent(:destroy) }
    it { should have_many(:participations).dependent(:destroy) }
    it { should have_many(:users).through(:participations) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:band) { create(:band, user: user) }
    let!(:dm_chat) { create(:chat, :direct_message) }

    describe '.band_chats' do
      it 'returns only chats associated with bands' do
        expect(Chat.band_chats).to include(band.chat)
        expect(Chat.band_chats).not_to include(dm_chat)
      end
    end

    describe '.direct_messages' do
      it 'returns only chats not associated with bands' do
        expect(Chat.direct_messages).to include(dm_chat)
        expect(Chat.direct_messages).not_to include(band.chat)
      end
    end
  end

  describe '.between' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    context 'when no DM chat exists between users' do
      it 'creates a new DM chat' do
        expect {
          Chat.between(user1, user2)
        }.to change(Chat, :count).by(1)
      end

      it 'creates participations for both users' do
        chat = Chat.between(user1, user2)
        expect(chat.users).to include(user1, user2)
      end

      it 'sets appropriate name for the chat' do
        chat = Chat.between(user1, user2)
        expect(chat.name).to include(user1.username)
        expect(chat.name).to include(user2.username)
      end
    end

    context 'when a DM chat already exists between users' do
      let!(:existing_chat) { Chat.between(user1, user2) }

      it 'returns the existing chat' do
        expect(Chat.between(user1, user2)).to eq(existing_chat)
      end

      it 'does not create a new chat' do
        expect {
          Chat.between(user1, user2)
        }.not_to change(Chat, :count)
      end
    end
  end

  describe '#direct_message?' do
    it 'returns true when band_id is nil' do
      chat = build(:chat, band: nil)
      expect(chat.direct_message?).to be true
    end

    it 'returns false when band_id is present' do
      band = create(:band)
      expect(band.chat.direct_message?).to be false
    end
  end

  describe '#other_participant' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:chat) { create(:chat, :direct_message, :with_participants, participants: [user1, user2]) }

    it 'returns the other user in a DM chat' do
      expect(chat.other_participant(user1)).to eq(user2)
      expect(chat.other_participant(user2)).to eq(user1)
    end
  end

  describe '#unread_count_for' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:chat) { create(:chat, :direct_message, :with_participants, participants: [user1, user2]) }

    it 'returns count of unread messages for a user' do
      # Message created by user2 automatically creates unread MessageRead for user1
      create(:message, chat: chat, user: user2)

      expect(chat.unread_count_for(user1)).to eq(1)
    end

    it 'returns 0 when all messages are read' do
      message = create(:message, chat: chat, user: user2)
      # Mark the auto-created message_read as read
      message.message_reads.find_by(user: user1).update!(read: true)

      expect(chat.unread_count_for(user1)).to eq(0)
    end
  end
end
