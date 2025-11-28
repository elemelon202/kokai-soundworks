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
    # see all musicians
    # singular musician
    # get that musicians bands / can do that with iteration
    #maybe have band name in card
    # Musician.new for create a profile button

    # for searching on the musicians index page -- kyle
    if params[:query].present?
      @musicians = @musicians.search_by_all(params[:query])
    end

    if params[:instrument].present?
      @musicians = @musicians.where(instrument: params[:instrument])
    end

    if params[:location].present?
      @musicians = @musicians.where(location: params[:location])
    end

  end

  def show
    authorize @musician
    #should be able to see a musician
    @musician = Musician.find(params[:id])
    # should be able to see bands the musician is in
    @bands = @musician.bands
    # should have a chat button?
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
end
