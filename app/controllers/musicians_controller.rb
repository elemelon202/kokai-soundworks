class MusiciansController < ApplicationController
  # find musician before performing show, edit, update, or destroy
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_musician, only: [:show, :edit, :update, :destroy]

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
  if @musician.update(musician_params)
    redirect_to musician_path(@musician), notice: 'Your profile has been updated'
  else
    render :edit, status: :unprocessable_entity
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
    params.require(:musician).permit(:name, :instrument, :age, :styles, :location, media: [])
  end

  def mark_invitation_notifications_as_read
    return unless current_user

    # Mark band invitation notifications as read
    current_user.notifications.unread
      .where(notification_type: Notification::TYPES[:band_invitation])
      .update_all(read: true)
  end
end
