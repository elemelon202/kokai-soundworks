class FansController < ApplicationController
  before_action :set_fan

  def show
    authorize @fan
    @upcoming_gigs = @fan.user.attending_gigs.where('date >= ?', Date.current)
    @past_gigs = @fan.user.attending_gigs.where('date < ?', Date.current)
    @following_musicians = @fan.user.followed_musicians
    @following_bands = @fan.user.followed_bands
  end

  def edit
    authorize @fan
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
    @upcoming = @fan.user.gig_attendances.joins(:gig).where('gigs.date >= ?', Date.current)
    @past = @fan.user.gig_attendances.joins(:gig).where('gigs.date < ?', Date.current)
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
