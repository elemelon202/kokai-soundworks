require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:kanban_tasks).with_foreign_key(:created_by_id).dependent(:destroy) }
    it { should have_many(:bands).dependent(:destroy) }
    it { should have_many(:participations).dependent(:destroy) }
    it { should have_many(:chats).through(:participations) }
    it { should have_many(:messages).dependent(:destroy) }
    it { should have_many(:venues).dependent(:destroy) }
    it { should have_many(:gigs).through(:venues) }
    it { should have_many(:bookings).through(:bands) }
    it { should have_many(:message_reads) }
    it { should have_many(:read_messages).through(:message_reads).source(:message) }
    it { should have_one(:musician).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
  end

  describe '#musician?' do
    it 'returns true when user_type is musician' do
      user = build(:user, user_type: 'musician')
      expect(user.musician?).to be true
    end

    it 'returns false when user_type is not musician' do
      user = build(:user, user_type: 'venue')
      expect(user.musician?).to be false
    end
  end

  describe '#band_leader?' do
    it 'returns true when user_type is band_leader' do
      user = build(:user, user_type: 'band_leader')
      expect(user.band_leader?).to be true
    end

    it 'returns false when user_type is not band_leader' do
      user = build(:user, user_type: 'musician')
      expect(user.band_leader?).to be false
    end
  end

  describe '#direct_message_chats' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'returns only direct message chats' do
      dm_chat = create(:chat, :direct_message, :with_participants, participants: [user1, user2])
      band = create(:band, user: user1)

      expect(user1.direct_message_chats).to include(dm_chat)
      expect(user1.direct_message_chats).not_to include(band.chat)
    end
  end

  describe '#unread_dm_count' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'returns count of unread messages in DM chats' do
      chat = create(:chat, :direct_message, :with_participants, participants: [user1, user2])
      message = create(:message, chat: chat, user: user2)
      create(:message_read, message: message, user: user1, read: false)

      expect(user1.unread_dm_count).to eq(1)
    end

    it 'returns 0 when all messages are read' do
      chat = create(:chat, :direct_message, :with_participants, participants: [user1, user2])
      message = create(:message, chat: chat, user: user2)
      create(:message_read, message: message, user: user1, read: true)

      expect(user1.unread_dm_count).to eq(0)
    end
  end

  describe '#chat_with' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'returns existing DM chat between users' do
      existing_chat = Chat.between(user1, user2)
      expect(user1.chat_with(user2)).to eq(existing_chat)
    end

    it 'creates a new DM chat if none exists' do
      expect { user1.chat_with(user2) }.to change(Chat, :count).by(1)
    end
  end
end
