class SpotifyTracksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_band
  before_action :authorize_band

  def create
    @track = @band.spotify_tracks.build(spotify_track_params)
    if @track.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to edit_band_path(@band), notice: 'Track added!' }
      end
    else
      redirect_to edit_band_path(@band), alert: @track.errors.full_messages.join(', ')
    end
  end

  def destroy
    @spotify_track = @band.spotify_tracks.find(params[:id])
    @spotify_track.destroy
    redirect_to edit_band_path(@band), notice: 'Spotify track was successfully removed.'
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def authorize_band
    authorize @band, :edit?
  end

  def spotify_track_params
    params.require(:spotify_track).permit(:spotify_url)
  end
end
