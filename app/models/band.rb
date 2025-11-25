class Band < ApplicationRecord
  #owner of the band is the user who created it
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :gigs, through: :bookings
  has_many :involvements, dependent: :destroy
  has_many :musicians, through: :involvements
  has_one :chat, dependent: :destroy
  has_many :messages, through: :chat
  after_create :create_band_chat
  accepts_nested_attributes_for :musicians
  acts_as_taggable_on :genres

  GENRES = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop', 'Country', 'Electronic', 'Reggae', 'Blues', 'Folk'].freeze

  scope :with_genres, ->(genres) { tagged_with(genres, on: :genres, any: true) }

  def unread_messages_for(user)
    return Message.none unless chat
    chat.messages.joins(:message_reads).where(message_reads: { user_id: user.id, read: false })
  end


  def create_band_chat
    # automatically create a chat for the band
    Chat.create(name: "#{name} Chat", band: self)
  end
end
