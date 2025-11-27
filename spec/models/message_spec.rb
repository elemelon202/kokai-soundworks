require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:chat) }
    it { should belong_to(:user) }
    it { should have_many(:attachments).dependent(:destroy) }
    it { should have_many(:message_reads).dependent(:destroy) }
    it { should have_many(:readers).through(:message_reads).source(:user) }
  end

  describe 'callbacks' do
    describe '#create_message_reads' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      let(:chat) { create(:chat, :direct_message, :with_participants, participants: [user1, user2, user3]) }

      it 'creates message_read records for all chat participants except sender' do
        expect {
          create(:message, chat: chat, user: user1)
        }.to change(MessageRead, :count).by(2)
      end

      it 'creates unread message_read records' do
        message = create(:message, chat: chat, user: user1)
        expect(message.message_reads.pluck(:read)).to all(be false)
      end

      it 'includes all participants except sender in message_reads' do
        message = create(:message, chat: chat, user: user1)
        reader_ids = message.message_reads.pluck(:user_id)
        expect(reader_ids).to include(user2.id, user3.id)
        expect(reader_ids).not_to include(user1.id)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid message' do
      chat = create(:chat)
      user = create(:user)
      create(:participation, chat: chat, user: user)
      message = build(:message, chat: chat, user: user)
      expect(message).to be_valid
    end
  end
end
