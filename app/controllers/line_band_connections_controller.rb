class LineBandConnectionsController < ApplicationController
  skip_after_action :verify_authorized

  before_action :set_band
  before_action :authorize_band_leader
  before_action :set_connection, only: [:destroy, :toggle_auto_create]

  def create
    # Check if band already has an active or pending connection
    existing = @band.line_band_connections.where(active: true).or(
      @band.line_band_connections.pending
    ).first

    if existing
      redirect_to edit_band_path(@band), alert: "This band already has a LINE connection."
      return
    end

    @connection = @band.line_band_connections.build(
      linked_by: current_user,
      auto_create_events: false
    )

    if @connection.save
      redirect_to edit_band_path(@band), notice: "LINE link code generated! Share the code with your LINE group."
    else
      redirect_to edit_band_path(@band), alert: "Failed to generate link code."
    end
  end

  def destroy
    if @connection.update(active: false, link_code: nil)
      redirect_to edit_band_path(@band), notice: "LINE group disconnected."
    else
      redirect_to edit_band_path(@band), alert: "Failed to disconnect LINE group."
    end
  end

  def toggle_auto_create
    @connection.update(auto_create_events: !@connection.auto_create_events)
    redirect_to edit_band_path(@band), notice: "Auto-create events #{@connection.auto_create_events ? 'enabled' : 'disabled'}."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_connection
    @connection = @band.line_band_connections.find(params[:id])
  end

  def authorize_band_leader
    unless @band.user_id == current_user.id
      redirect_to edit_band_path(@band), alert: "Only the band leader can manage LINE integration."
    end
  end
end
