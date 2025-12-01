class FansController < ApplicationController
  before_action :set_fan

  def show
    authorize @fan
    # Only show gigs the user is interested in or going to
    @upcoming_gigs = Gig.joins(:gig_attendances)
                        .where(gig_attendances: { user_id: @fan.user_id, status: [:interested, :going] })
                        .where('gigs.date >= ?', Date.current)
                        .includes(:venue)
                        .order(:date)
    @past_gigs = @fan.user.gig_attendances.attended.joins(:gig).where('gigs.date < ?', Date.current).map(&:gig)
    @following_musicians = @fan.user.followed_musicians
    @following_bands = @fan.user.followed_bands
  end

  def edit
    authorize @fan
    # Upcoming shows in the area (based on fan's location)
    @area_gigs = Gig.includes(:venue, :bands).where('date >= ?', Date.current).order(:date)
    if @fan.location.present?
      @area_gigs = @area_gigs.joins(:venue).where("venues.city ILIKE ?", "%#{@fan.location.split(',').first.strip}%")
    end
    @area_gigs = @area_gigs.limit(5)
  end

  def update
    authorize @fan
    if @fan.update(fan_params)
      redirect_to @fan, notice: 'Profile updated.'
    else
      render :edit
    end
  end

  def gigs
    authorize @fan
    @upcoming = @fan.user.gig_attendances.where(status: [:interested, :going]).joins(:gig).where('gigs.date >= ?', Date.current)
    @past = @fan.user.gig_attendances.attended.joins(:gig).where('gigs.date < ?', Date.current)
  end

  def following
    authorize @fan
    @musicians = @fan.user.followed_musicians
    @bands = @fan.user.followed_bands
  end

  def saved
    authorize @fan
    @musicians = @fan.user.saved_musicians
    @bands = @fan.user.saved_bands
  end

  def friends
    authorize @fan
    @friends = @fan.user.friends
  end

  private

  def set_fan
    @fan = Fan.find(params[:id])
  end

  def fan_params
    params.require(:fan).permit(:display_name, :bio, :location, :avatar, :banner, :favorite_genres, :social_instagram, :social_twitter, :social_spotify)
  end
end
