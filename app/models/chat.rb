class Chat < ApplicationRecord
  belongs_to :band, optional: true
  has_many :messages, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations

  scope :band_chats, -> { where.not(band_id: nil) }
  scope :direct_messages, -> { where(band_id: nil) }

  def self.between(user1, user2)
    # Find existing DM chat between these two users
    chat_ids = Participation.select(:chat_id)
                            .where(user_id: [user1.id, user2.id])
                            .group(:chat_id)
                            .having('COUNT(DISTINCT user_id) = 2')
                            .pluck(:chat_id)

    chat = Chat.where(id: chat_ids, band_id: nil).first

    unless chat
      chat = Chat.create!(name: "DM: #{user1.username} & #{user2.username}")
      chat.participations.create!(user: user1)
      chat.participations.create!(user: user2)
    end

    chat
  end

  def direct_message?
    band_id.nil?
  end

  def other_participant(current_user)
    users.where.not(id: current_user.id).first
  end

  def unread_count_for(user)
    messages.joins(:message_reads)
      .where(message_reads: { user_id: user.id, read: false })
      .count
  end
end
