class MusicianShortsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_musician, only: [:new, :create, :update, :edit, :destroy, :reorder]
  before_action :set_short, only: [:edit, :update, :destroy]

  def index
    # Get all shorts with their musicians for infinite scroll feed
    @shorts = MusicianShort.includes(musician: [:user, :avatar_attachment, :banner_attachment])
                           .includes(video_attachment: :blob)
                           .order("RANDOM()")
                           .limit(10)

    # Skip both authorization and policy scoping for public discover page
    skip_authorization
    skip_policy_scope
  end

  def new
    @short = @musician.musician_shorts.build
    authorize @short
  end

  def create
    @short = @musician.musician_shorts.build(short_params)
    authorize @short
    if @short.save
      redirect_to musician_path(@musician), notice: 'Short uploaded successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @short
  end

  def update
    authorize @short
    if @short.update(short_params)
      redirect_to musician_path(@musician), notice: 'Short updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @short
    @short.destroy
    redirect_to musician_path(@musician), notice: 'Short deleted.'
  end

  def reorder
    # Build a temporary short for authorization check
    @short = @musician.musician_shorts.build
    authorize @short
    params[:short_ids].each_with_index do |id, index|
      short = @musician.musician_shorts.find(id)
      short.update(position: index)
    end
    head :ok
  end

  def like
    @short = MusicianShort.find(params[:id])
    skip_authorization

    unless current_user.liked_shorts.include?(@short)
      current_user.liked_shorts << @short
      Activity.track(user: current_user, action: :like_short, trackable: @short, musician: @short.musician)
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: discover_shorts_path }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "like-button-#{@short.id}",
          partial: "musician_shorts/like_button",
          locals: { short: @short }
        )
      }
    end
  end

  def unlike
    @short = MusicianShort.find(params[:id])
    skip_authorization

    current_user.liked_shorts.delete(@short)

    respond_to do |format|
      format.html { redirect_back fallback_location: discover_shorts_path }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "like-button-#{@short.id}",
          partial: "musician_shorts/like_button",
          locals: { short: @short }
        )
      }
    end
  end

  private

  def set_musician
    @musician = Musician.find(params[:musician_id])
  end

  def set_short
    @short = @musician.musician_shorts.find(params[:id])
  end

  def short_params
    params.require(:musician_short).permit(:title, :description, :video, :position)
  end
end
