class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :kanban_tasks, foreign_key: :created_by_id, dependent: :destroy
  has_many :bands, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :chats, through: :participations
  has_many :messages, dependent: :destroy
  has_many :venues, dependent: :destroy
  # has_many :musicians, dependent: :destroy #A user can only have one musician, itself right?
  has_many :gigs, through: :venues
  has_many :bookings, through: :bands
  has_many :message_reads
  has_many :read_messages, through: :message_reads, source: :message
  has_one :musician, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :short_likes, dependent: :destroy
  has_many :liked_shorts, through: :short_likes, source: :musician_short
  has_many :short_comments, dependent: :destroy

  # convenience: check roles
  def musician?
    user_type == "musician"
  end

  def band_leader?
    user_type == "band_leader"
  end

  def direct_message_chats
    chats.direct_messages.includes(:messages, :users)
  end

  def unread_dm_count
    MessageRead.joins(:message)
      .where(user_id: id, read: false)
      .where(messages: { chat_id: chats.direct_messages.pluck(:id) })
      .count
  end

  def chat_with(other_user)
    Chat.between(self, other_user)
  end
end
