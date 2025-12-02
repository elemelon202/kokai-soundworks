#THE ACTIVITY TRACKER USES THE RAILS POLYMORPHIC ASSOCIATION TO BASICALLY MAKE A RECORD EVERYTIME ANYONE DOES ANYTHING. THEN IT USERS THE MUSICIAN ID TO POST THAT TO THE PROFILE OF THE RELEVANT MUSICIAN.

class MusiciansController < ApplicationController
  # find musician before performing show, edit, update, or destroy
  skip_before_action :authenticate_user!, only: [:index, :show, :search]
  before_action :set_musician, only: [:show, :edit, :update, :destroy, :purge_attachment]

  def search
    @musicians = policy_scope(Musician)

    if params[:query].present?
      @musicians = @musicians.search_by_all(params[:query])
    end

    # Exclude the current user's musician profile if they have one
    if current_user&.musician
      @musicians = @musicians.where.not(id: current_user.musician.id)
    end

    @musicians = @musicians.limit(20)

    render json: @musicians.map { |m|
      {
        id: m.id,
        name: m.name,
        instrument: m.instrument,
        location: m.location,
        display: "#{m.name} - #{m.instrument}#{m.location.present? ? " (#{m.location})" : ""}"
      }
    }
  end

  def index
    @musicians = policy_scope(Musician)

    # for searching on the musicians index page
    if params[:query].present?
      @musicians = @musicians.search_by_all(params[:query])
    end

    if params[:instrument].present?
      @musicians = @musicians.where(instrument: params[:instrument])
    end

    if params[:location].present?
      @musicians = @musicians.where(location: params[:location])
    end

    # Order by musicians with photos first (avatar or media), then by created_at
    musicians_with_photos = Musician.joins(:avatar_attachment).pluck(:id) +
                           Musician.joins(:media_attachments).pluck(:id)
    musicians_with_photos = musicians_with_photos.uniq

    @musicians = @musicians.order(
      Arel.sql("CASE WHEN musicians.id IN (#{musicians_with_photos.join(',').presence || '0'}) THEN 0 ELSE 1 END"),
      created_at: :desc
    )

    # Paginate results - 10 per page
    @pagy, @musicians = pagy(@musicians, items: 10)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @musician
    #should be able to see a musician
    @musician = Musician.find(params[:id])
    # should be able to see bands the musician is in
    @bands = @musician.bands
    track_profile_view(@musician)
  end

  def new
    #create a profile?
    @musician = Musician.new
    authorize @musician
  end

  def create
    @musician = Musician.new(musician_params)
    @musician.user = current_user
    authorize @musician
    if @musician.save
      redirect_to musician_path(@musician), notice: 'Profile has been created'
    else render :new, status: :unprocessable_entity
    end
  end

def edit
  authorize @musician
  @band_invitation = BandInvitation.find_by(musician: current_user.musician, status: "Pending")

  # Mark band invitation notifications as read when visiting edit page
  mark_invitation_notifications_as_read

   # Calculate mainstage stats for current contest
    current_contest = MainstageContest.current_contest
    mainstage_engagement = 0
    mainstage_votes = 0
    mainstage_total = 0
    mainstage_rank = nil

    if current_contest
      leaderboard = current_contest.leaderboard(100)
      musician_entry = leaderboard.find { |e| e[:musician].id == @musician.id }
      if musician_entry
        mainstage_engagement = musician_entry[:engagement_score]
        mainstage_votes = musician_entry[:vote_score] / 10  # Convert back to vote count
        mainstage_total = musician_entry[:total_score]
        mainstage_rank = leaderboard.index(musician_entry) + 1
      end
    end

    @stats = {
      followers_count: @musician.followers.count,
      profile_views_week: @musician.profile_views.where(viewed_at: 1.week.ago..).count,
      profile_views_total: @musician.profile_views.count,
      profile_saves: @musician.profile_saves.count,
      new_followers_week: @musician.follows.where(created_at: 1.week.ago..).count,
      mainstage_wins: @musician.mainstage_win_count,
      mainstage_engagement: mainstage_engagement,
      mainstage_votes: mainstage_votes,
      mainstage_total: mainstage_total,
      mainstage_rank: mainstage_rank
    }
end

def update
  authorize @musician
  @musician = Musician.find(params[:id])

  # Handle media attachments separately to append instead of replace
  attach_new_media

  if @musician.update(musician_params_without_media)
    redirect_to musician_path(@musician), notice: 'Your profile has been updated'
  else
    render :edit, status: :unprocessable_entity
  end
end

def purge_attachment
  authorize @musician
  attachment = ActiveStorage::Attachment.find(params[:attachment_id])

  if attachment.record == @musician
    attachment.purge
    redirect_to edit_musician_path(@musician), notice: "Media removed successfully."
  else
    redirect_to edit_musician_path(@musician), alert: "Unable to remove that media."
  end
end

  def destroy
    authorize @musician
    @musician.destroy
    redirect_to root_path, status: :see_other, notice: 'You have deleted your account. We hope to see you again'
  end

  def follow
    @musician = Musician.find(params[:id])
    skip_authorization

    unless current_user.followed_musicians.include?(@musician)
      current_user.followed_musicians << @musician
      Activity.track(user: current_user, action: :follow, trackable: @musician, musician: @musician)
      follow = Follow.find_by(follower: current_user, followable: @musician)
      Notification.create_for_new_follower(follow) if follow
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: musician_path(@musician) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "follow-button-musician-#{@musician.id}",
          partial: "musicians/follow_button",
          locals: { musician: @musician }
        )
      }
    end
  end

  def unfollow
    @musician = Musician.find(params[:id])
    skip_authorization

    current_user.followed_musicians.delete(@musician)

    respond_to do |format|
      format.html { redirect_back fallback_location: musician_path(@musician) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "follow-button-musician-#{@musician.id}",
          partial: "musicians/follow_button",
          locals: { musician: @musician }
        )
      }
    end
  end

   def save_profile
    @musician = Musician.find(params[:id])
    skip_authorization

    unless current_user.saved_musicians.include?(@musician)
      current_user.saved_musicians << @musician
      Activity.track(user: current_user, action: :save, trackable: @musician, musician: @musician)
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: musician_path(@musician) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "save-button-musician-#{@musician.id}",
          partial: "musicians/save_button",
          locals: { musician: @musician }
        )
      }
    end
   end

  def unsave_profile
    @musician = Musician.find(params[:id])
    skip_authorization

    current_user.saved_musicians.delete(@musician)

    respond_to do |format|
      format.html { redirect_back fallback_location: musician_path(@musician) }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "save-button-musician-#{@musician.id}",
          partial: "musicians/save_button",
          locals: { musician: @musician }
        )
      }
    end
  end

  private

  def set_musician
    @musician = Musician.find(params[:id])
  end

  def musician_params
    params.require(:musician).permit(:name, :instrument, :age, :styles, :location, :bio, :avatar, :banner, :banner_position, images: [], videos: [])
  end

  def musician_params_without_media
    params.require(:musician).permit(:name, :instrument, :age, :styles, :location, :bio, :banner_position)
  end

  def attach_new_media
    return unless params[:musician].present?

    # Only update avatar if a new one was uploaded
    if params[:musician][:avatar].present?
      @musician.avatar.purge if @musician.avatar.attached?
      @musician.avatar.attach(params[:musician][:avatar])
    end

    # Only update banner if a new one was uploaded
    if params[:musician][:banner].present?
      @musician.banner.purge if @musician.banner.attached?
      @musician.banner.attach(params[:musician][:banner])
    end

    # Append new images instead of replacing existing ones
    if params[:musician][:images].present?
      params[:musician][:images].each do |image|
        @musician.images.attach(image)
      end
    end

    # Append new videos instead of replacing existing ones
    if params[:musician][:videos].present?
      params[:musician][:videos].each do |video|
        @musician.videos.attach(video)
      end
    end
  end

  def mark_invitation_notifications_as_read
    return unless current_user

    # Mark band invitation notifications as read
    current_user.notifications.unread
      .where(notification_type: Notification::TYPES[:band_invitation])
      .update_all(read: true)
  end

  def track_profile_view(profile)
    return if current_user&.musician == profile

    ProfileView.create!(
      viewer: current_user,
      viewable: profile,
      viewed_at: Time.current,
      ip_hash: current_user ? nil : Digest::SHA256.hexdigest(request.remote_ip)[0..15] #this is so we can count unique non members to the site. if they are logged in, we can count their user_id, but if they aren't, we can take their ip, hash it up and protect privacy and just take the first 16 digits. This way we know how many views a profile got. -Sam the spy
    )
  end
end
