class BandsController < ApplicationController
  # I added a bands policy so I edited some of the functions (marked with a star)
  # added skip_before_action so public users can see these pages.
  skip_before_action :authenticate_user!, only: [:index, :show]
  # before_action :authenticate_user! - **Tyrhen edited this out so it doesn't override line 4**
  before_action :set_band, only: [:show, :edit, :update, :destroy, :transfer_leadership, :purge_attachment]
  before_action :authorize_band, only: [:edit, :update, :destroy, :purge_attachment]
  before_action :authorize_leader, only: [:transfer_leadership]

  def index
    @bands = policy_scope(Band) #<--- This is all you need for the index to bypass pundit - Tyrhen
    @bands = Band.all

     if params[:genres].present?
    @bands = Band.with_genres(params[:genres])
     end
      if params[:q].present?
    @bands = @bands.where("name ILIKE ?", "%#{params[:q]}%")
      end

    # Paginate results - 10 per page
    @pagy, @bands = pagy(@bands, items: 10)
  end
  def show
    authorize @band
    track_profile_view(@band)
  end
  def new
    @band = Band.new
    @other_user = @chat.recipient.musician if @chat.present?
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

    # Next upcoming gig for countdown (from manually added band gigs)
    @next_gig = @band.band_gigs.upcoming.first

    # app/controllers/bands_controller.rb
  @chat = @band.chat || @band.create_band_chat(name: "#{@band.name} Chat")

  # All messages for the chat
  @messages = @chat.messages.order(created_at: :asc)

  # Get unread count before marking as read (for display)
  unread_query = MessageRead.where(user_id: current_user.id, read: false)
                            .where(message_id: @chat.messages.select(:id))
  @unread_count = unread_query.count

  # Mark unread messages as read using a single query
  unread_query.update_all(read: true)
    @band_invitation = BandInvitation.new
    # Show all pending invitations for this band (visible to all band members)
    @pending_invitations = @band.band_invitations.pending

    # Mark band-related notifications as read when visiting the dashboard
    mark_band_notifications_as_read

    # Calculate mainstage stats for current contest
    current_contest = BandMainstageContest.current_contest
    mainstage_engagement = 0
    mainstage_votes = 0
    mainstage_total = 0
    mainstage_rank = nil

    if current_contest
      leaderboard = current_contest.leaderboard(100)
      band_entry = leaderboard.find { |e| e[:band].id == @band.id }
      if band_entry
        mainstage_engagement = band_entry[:engagement_score]
        mainstage_votes = band_entry[:vote_score] / 10  # Convert back to vote count
        mainstage_total = band_entry[:total_score]
        mainstage_rank = leaderboard.index(band_entry) + 1
      end
    end

    # Analytics stats for the band
    @stats = {
      followers_count: @band.followers.count,
      profile_views_week: @band.profile_views.where(viewed_at: 1.week.ago..).count,
      profile_views_total: @band.profile_views.count,
      profile_saves: @band.profile_saves.count,
      new_followers_week: @band.follows.where(created_at: 1.week.ago..).count,
      mainstage_wins: @band.mainstage_win_count,
      mainstage_engagement: mainstage_engagement,
      mainstage_votes: mainstage_votes,
      mainstage_total: mainstage_total,
      mainstage_rank: mainstage_rank
    }
  end
  def update
    authorize @band #* Tyrhen was here

    # Handle media attachments separately to append instead of replace
    attach_new_media

    if @band.update(band_params_without_media)
      redirect_to band_path(@band)
    else
      render :edit
    end
  end
  def destroy
    authorize @band #* Tyrhen was here
    band_name = @band.name
    @band.destroy
    redirect_to bands_path, notice: "#{band_name} has been deleted."
  end

  def transfer_leadership
    authorize @band
    # Validate that a musician was selected
    if params[:musician_id].blank?
      redirect_to edit_band_path(@band), alert: "Please select a band member to transfer leadership to."
      return
    end

    new_leader_musician = Musician.find_by(id: params[:musician_id])

    # Ensure the musician exists
    unless new_leader_musician
      redirect_to edit_band_path(@band), alert: "Musician not found."
      return
    end

    new_leader_user = new_leader_musician.user

    # Ensure the new leader is a member of the band
    unless @band.musicians.include?(new_leader_musician)
      redirect_to edit_band_path(@band), alert: "That musician is not a member of this band."
      return
    end

    # Ensure the new leader is not already the leader
    if @band.user_id == new_leader_user.id
      redirect_to edit_band_path(@band), alert: "This musician is already the band leader."
      return
    end

    # Transfer leadership
    @band.update!(user: new_leader_user)

    redirect_to edit_band_path(@band), notice: "Leadership transferred to #{new_leader_musician.name}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_band_path(@band), alert: "Failed to transfer leadership: #{e.message}"
  end

  def purge_attachment
    authorize @band
    attachment = ActiveStorage::Attachment.find(params[:attachment_id])

    # Verify the attachment belongs to this band
    if attachment.record == @band
      attachment.purge
      redirect_to edit_band_path(@band), notice: "Media removed successfully."
    else
      redirect_to edit_band_path(@band), alert: "Unable to remove that media."
    end
  end

  def follow
    @band = Band.find(params[:id])
    skip_authorization

    unless current_user.followed_bands.include?(@band)
      current_user.followed_bands << @band
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: band_path(@band) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "follow-button-band-#{@band.id}",
          partial: "bands/follow_button",
          locals: { band: @band }
        )
      }
    end
  end

  def unfollow
    @band = Band.find(params[:id])
    skip_authorization

    current_user.followed_bands.delete(@band)

    respond_to do |format|
      format.html { redirect_back fallback_location: band_path(@band) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "follow-button-band-#{@band.id}",
          partial: "bands/follow_button",
          locals: { band: @band }
        )
      }
    end
  end

   def save_profile
    @band = Band.find(params[:id])
    skip_authorization

    unless current_user.saved_bands.include?(@band)
      current_user.saved_bands << @band
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: band_path(@band) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "save-button-band-#{@band.id}",
          partial: "bands/save_button",
          locals: { band: @band }
        )
      }
    end
   end

  def unsave_profile
    @band = Band.find(params[:id])
    skip_authorization

    current_user.saved_bands.delete(@band)

    respond_to do |format|
      format.html { redirect_back fallback_location: band_path(@band) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "save-button-band-#{@band.id}",
          partial: "bands/save_button",
          locals: { band: @band }
        )
      }
    end
  end

  private
  def band_params
    # Don't permit musician_ids - we handle invitations separately
    params.require(:band).permit(:name, :location, :description, :banner, genre_list: [], images: [], videos: [])
  end

  def band_params_without_media
    # Exclude media attachments - they're handled separately in attach_new_media
    params.require(:band).permit(
      :name, :location, :description, :banner_position,
      :instagram_handle, :instagram_followers,
      :tiktok_handle, :tiktok_followers,
      :youtube_handle, :youtube_subscribers,
      :twitter_handle, :twitter_followers,
      genre_list: []
    )
  end

  def attach_new_media
    return unless params[:band].present?

    # Only update banner if a new one was uploaded
    if params[:band][:banner].present?
      # Purge old banner first to ensure clean replacement
      @band.banner.purge if @band.banner.attached?
      @band.banner.attach(params[:band][:banner])
    end

    # Append new images instead of replacing existing ones
    if params[:band][:images].present?
      params[:band][:images].each do |image|
        @band.images.attach(image)
      end
    end

    # Append new videos instead of replacing existing ones
    if params[:band][:videos].present?
      params[:band][:videos].each do |video|
        @band.videos.attach(video)
      end
    end
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

  def authorize_leader
    unless @band.user_id == current_user.id
      redirect_to edit_band_path(@band), alert: "Only the band leader can perform this action."
    end
  end

  def mark_band_notifications_as_read
    return unless current_user

    # Mark notifications related to this band as read
    band_notification_types = [
      Notification::TYPES[:band_message],
      Notification::TYPES[:band_member_joined],
      Notification::TYPES[:band_member_left]
    ]

    # Find notifications where the notifiable is related to this band
    current_user.notifications.unread.where(notification_type: band_notification_types).find_each do |notification|
      # Check if notification is related to this band
      if notification.notifiable.respond_to?(:chat) && notification.notifiable.chat&.band_id == @band.id
        notification.update(read: true)
      elsif notification.notifiable == @band
        notification.update(read: true)
      end
    end
  end

  def track_profile_view(profile)
    return if current_user&.musician && profile.musicians.include?(current_user.musician)

    ProfileView.create(
      viewer: current_user,
      viewable: profile,
      viewed_at: Time.current,
      ip_hash: current_user ? nil : Digest::SHA256.hexdigest(request.remote_ip)[0..15]
    )
  end
end
