class BandsController < ApplicationController
  # I added a bands policy so I edited some of the functions (marked with a star)
  # added skip_before_action so public users can see these pages.
  skip_before_action :authenticate_user!, only: [:index, :show]
  # before_action :authenticate_user! - **Tyrhen edited this out so it doesn't override line 4**
  before_action :set_band, only: [:show, :edit, :update, :destroy]
  before_action :authorize_band, only: [:edit, :update, :destroy]

  def index
    @bands = policy_scope(Band) #<--- This is all you need for the index to bypass pundit - Tyrhen
    @bands = Band.all

     if params[:genres].present?
    @bands = Band.with_genres(params[:genres])
     end
      if params[:q].present?
    @bands = @bands.where("name ILIKE ?", "%#{params[:q]}%")
      end
  end
  def show
    authorize @band
  end
  def new
    @band = Band.new
    authorize @band #* Tyrhen was here
  end
  def create
    @band = Band.new(band_params)
    @band.user = current_user
    @band.leader_musician_params = leader_musician_params if leader_musician_params.present?
    authorize @band #* Tyrhen was here
    if @band.save
      # Send invitations to selected musicians instead of adding them directly
      send_invitations_to_musicians
      redirect_to band_path(@band)
    else
      render :new
    end
  end
  def edit
    authorize @band #* Tyrhen was here
    @pending_bookings = @band.bookings.where(status: 'pending')
    # app/controllers/bands_controller.rb
  @chat = @band.chat || @band.create_band_chat(name: "#{@band.name} Chat")

  # All messages for the chat
  @messages = @chat.messages.order(created_at: :asc)

  # Unread messages for current_user
  @unread_messages = @chat.messages.joins(:message_reads)
                           .where(message_reads: { user_id: current_user.id, read: false })

  # Mark unread messages as read
  @unread_messages.each do |msg|
    msg_read = msg.message_reads.find_by(user: current_user)
    msg_read.update(read: true) if msg_read
    end
    @band_invitation = BandInvitation.new
    # Show all pending invitations for this band (visible to all band members)
    @pending_invitations = @band.band_invitations.pending

  end
  def update
    authorize @band #* Tyrhen was here
    if @band.update(band_params)
      redirect_to band_path(@band)
    else
      render :edit
    end
  end
  def destroy
    authorize @band #* Tyrhen was here
    @band.destroy
    redirect_to bands_path
  end

  private
  def band_params
    # Don't permit musician_ids - we handle invitations separately
    params.require(:band).permit(:name, :location, :description, genre_list: [])
  end

  def invited_musician_ids
    params[:band][:musician_ids]&.reject(&:blank?) || []
  end

  def send_invitations_to_musicians
    invited_musician_ids.each do |musician_id|
      musician = Musician.find_by(id: musician_id)
      next unless musician
      # Don't invite the band creator (they're already a member)
      next if musician.user_id == current_user.id

      @band.band_invitations.create(
        musician: musician,
        inviter: current_user,
        status: 'Pending'
      )
    end
  end

  def leader_musician_params
    return nil unless params[:band][:leader_musician].present?
    params[:band].require(:leader_musician).permit(:name, :instrument, :location, :media)
  end

  def set_band
    @band = Band.find(params[:id])
  end
  def authorize_band
    unless @band.user == current_user || user_is_band_member?
      redirect_to bands_path, alert: "You are not authorized to perform this action."
    end
  end

  def user_is_band_member?
    return false unless current_user&.musician
    @band.musicians.include?(current_user.musician)
  end
end
