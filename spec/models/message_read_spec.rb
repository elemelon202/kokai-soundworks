require 'rails_helper'

RSpec.describe MessageRead, type: :model do
  describe 'associations' do
    it { should belong_to(:message) }
    it { should belong_to(:user) }
  end

  describe 'scopes' do
    describe '.unread' do
      let(:user) { create(:user) }
      let(:chat) { create(:chat, :with_participants, participants: [user]) }
      let(:message) { create(:message, chat: chat, user: user) }

      it 'returns only unread message_reads' do
        unread = create(:message_read, message: message, user: user, read: false)
        read = create(:message_read, :read, message: message, user: create(:user))

        expect(MessageRead.unread).to include(unread)
        expect(MessageRead.unread).not_to include(read)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid message_read' do
      message_read = build(:message_read)
      expect(message_read).to be_valid
    end
  end
end
