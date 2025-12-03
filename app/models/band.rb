#Every band has a leader who is the user that created the band. The leader is automatically added as a member of the band upon creation as a musician, because only musicians can be members of bands.
#If the leader does not have a musician profile, one is created for them with default values.
#A band can have multiple musicians as members through the Involvement model.
#When a band is created, a chat is also created for the band, and the leader is added as a participant in that chat. Leadership is transferable to other memebers.
#To transfer leadership the band.user_id must be updated to the user_id of another member's musician profile.
#Only the leader can delete the band, but other members can leave. The leader cannot leave until they transfer leadership to another member.

class Band < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :gigs, through: :bookings
  has_many :involvements, dependent: :destroy
  has_many :musicians, through: :involvements
  has_many :band_invitations, dependent: :destroy
  has_many :spotify_tracks, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy # Enable follow functionality
  has_many :followers, through: :follows, source: :follower # Users who follow this band
  has_many :profile_saves, as: :saveable, class_name: 'ProfileSave', dependent: :destroy
  has_many :profile_views, as: :viewable, dependent: :destroy # Track profile views
  has_many :posts, dependent: :destroy # Band feed posts
  has_many :band_mainstage_votes, dependent: :destroy
  has_many :band_mainstage_wins, class_name: 'BandMainstageWinner', dependent: :destroy
  accepts_nested_attributes_for :spotify_tracks, allow_destroy: true, reject_if: :all_blank
  has_many :gig_applications, dependent: :destroy
  has_many :kanban_tasks, dependent: :destroy
  has_many :band_gigs, dependent: :destroy

  has_one :chat, dependent: :destroy
  has_many :messages, through: :chat

  # Media attachments
  has_one_attached :banner
  has_many_attached :images
  has_many_attached :videos

  after_create :setup_band_membership_and_chat

  acts_as_taggable_on :genres
  accepts_nested_attributes_for :musicians

  # Temporary attribute to pass musician profile data from controller
  attr_accessor :leader_musician_params

  GENRES = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop', 'Country', 'Electronic', 'Reggae', 'Blues', 'Folk'].freeze

  scope :with_genres, ->(genres) { tagged_with(genres, on: :genres, any: true) }

  # Check if band has won MAINSTAGE
  def mainstage_winner?
    band_mainstage_wins.exists?
  end

  def mainstage_win_count
    band_mainstage_wins.count
  end

  def latest_mainstage_win
    band_mainstage_wins.recent.first
  end

  private

  #NOTE: This method ensures that when a band is created, the creator is added as a member and a chat is set up.
  #In order for a User to create a Band, they must have a Musician profile. If they don't, one is created with default values.
  #A musician profile is necessary to be part of a Band. The method also creates a chat for the band and adds the creator as a participant.
  #Theres no need for a user to have a musician profile before creating a band; the method handles that automatically.
  #A User can still use the platform  without being a Musician so long as they don't create a Band.

  def setup_band_membership_and_chat
    # Ensure creator has a musician profile
    creator_musician = user.musician || create_leader_musician

    # Add creator to band members
    involvements.create!(musician: creator_musician)

    # Create the band chat
    chat_record = Chat.create!(band: self, name: "#{name} Chat")

    # Add creator as chat participant
    chat_record.participations.create!(user: user)
  end

  def create_leader_musician
    musician_attrs = if leader_musician_params.present?
      {
        user: user,
        name: leader_musician_params[:name].presence || user.username,
        instrument: leader_musician_params[:instrument].presence || "Unknown",
        location: leader_musician_params[:location].presence || "",
        styles: "",
        bio: ""
      }
    else
      {
        user: user,
        name: user.username,
        instrument: "Unknown",
        styles: "",
        location: "",
        bio: ""
      }
    end

    musician = Musician.create!(musician_attrs)

    # Attach photo if provided
    if leader_musician_params.present? && leader_musician_params[:media].present?
      musician.media.attach(leader_musician_params[:media])
    end

    musician
  end
end
