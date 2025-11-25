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
  # Tyrhen added this
  has_one  :musician, dependent: :destroy

  def musician?
    user_type == 'musician'
  end
end
