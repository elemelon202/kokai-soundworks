class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  has_many :attachments, dependent: :destroy
  has_many :message_reads, dependent: :destroy
  has_many :readers, through: :message_reads, source: :user

  after_create :create_message_reads

  private

  def create_message_reads
    # Create a MessageRead record for each user in the chat except the sender
    chat.users.where.not(id: user_id).each do |participant|
      MessageRead.create(message: self, user: participant, read: false)
    end
  end
end
