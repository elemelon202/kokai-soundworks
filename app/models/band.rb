class Band < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :gigs, through: :bookings
  has_many :involvements, dependent: :destroy
  has_many :musicians, through: :involvements

  has_one :chat, dependent: :destroy
  has_many :messages, through: :chat

  after_create :setup_band_membership_and_chat

  acts_as_taggable_on :genres
  accepts_nested_attributes_for :musicians

  GENRES = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop', 'Country', 'Electronic', 'Reggae', 'Blues', 'Folk'].freeze

  scope :with_genres, ->(genres) { tagged_with(genres, on: :genres, any: true) }

  private

  #NOTE: This method ensures that when a band is created, the creator is added as a member and a chat is set up.
  #In order for a User to create a Band, they must have a Musician profile. If they don't, one is created with default values.
  #A musician profile is necessary to be part of a Band. The method also creates a chat for the band and adds the creator as a participant.
  #Theres no need for a user to have a musician profile before creating a band; the method handles that automatically.
  #A User can still use the platform  without being a Musician so long as they don't create a Band.

  def setup_band_membership_and_chat
    # Ensure creator has a musician profile
    creator_musician = user.musician || Musician.create!(
      user: user,
      name: user.username,
      instrument: "Unknown",
      styles: "",
      location: "",
      bio: ""
    )

    # Add creator to band members
    involvements.create!(musician: creator_musician)

    # Create the band chat
    chat_record = Chat.create!(band: self, name: "#{name} Chat")

    # Add creator as chat participant
    chat_record.participations.create!(user: user)
  end
end
