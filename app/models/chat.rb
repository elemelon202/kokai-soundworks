class Chat < ApplicationRecord
  belongs_to :band, optional: true  # Make band optional for direct messages
  has_many :messages, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations

  # Scope for band chats
  scope :band_chats, -> { where.not(band_id: nil) }

  # Scope for direct message chats
  scope :direct_messages, -> { where(band_id: nil) }

  # Find or create a direct message chat between two users
  def self.between(user1, user2)
    # Find existing chat between these two users
    chat = joins(:participations)
      .where(band_id: nil)
      .group('chats.id')
      .having('COUNT(participations.id) = 2')
      .where(participations: { user_id: [user1.id, user2.id] })
      .first

    # Create new chat if none exists
    unless chat
      chat = self.create(name: "DM: #{user1.username} & #{user2.username}")
      chat.participations.create(user_id: user1.id)
      chat.participations.create(user_id: user2.id)
    end

    chat
  end

  # Check if this is a direct message chat
  def direct_message?
    band_id.nil?
  end

  # Get the other participant in a DM (not the current user)
  def other_participant(current_user)
    users.where.not(id: current_user.id).first
  end

  # Get unread message count for a user
  def unread_count_for(user)
    messages.joins(:message_reads)
      .where(message_reads: { user_id: user.id, read: false })
      .count
  end
end
