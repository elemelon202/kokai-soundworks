class BandEventsController < ApplicationController
  skip_after_action :verify_authorized
  before_action :authenticate_user!
  before_action :set_band
  before_action :set_band_event, only: [:update, :destroy]
  before_action :authorize_leader, only: [:create, :update, :destroy]

  def create
    @band_event = @band.band_events.build(band_event_params)

    if @band_event.save
      redirect_to edit_band_path(@band), notice: "Event added to calendar."
    else
      redirect_to edit_band_path(@band), alert: "Failed to add event: #{@band_event.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @band_event.update(band_event_params)
      redirect_to edit_band_path(@band), notice: "Event updated."
    else
      redirect_to edit_band_path(@band), alert: "Failed to update event."
    end
  end

  def destroy
    @band_event.destroy
    redirect_to edit_band_path(@band), notice: "Event removed from calendar."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_band_event
    @band_event = @band.band_events.find(params[:id])
  end

  def authorize_leader
    unless @band.user_id == current_user.id
      redirect_to edit_band_path(@band), alert: "Only the band leader can manage events."
    end
  end

  def band_event_params
    params.require(:band_event).permit(:title, :event_type, :date, :start_time, :end_time, :location, :description)
  end
end
