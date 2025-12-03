class MemberAvailabilitiesController < ApplicationController
  skip_after_action :verify_authorized
  before_action :authenticate_user!
  before_action :set_band
  before_action :ensure_band_member
  before_action :set_member_availability, only: [:destroy]

  def create
    @member_availability = @band.member_availabilities.build(member_availability_params)
    @member_availability.musician = current_user.musician

    if @member_availability.save
      redirect_to edit_band_path(@band, anchor: "my-availabilities-list"), notice: "Availability updated."
    else
      redirect_to edit_band_path(@band, anchor: "my-availabilities-list"), alert: "Failed to update availability: #{@member_availability.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    if @member_availability.musician == current_user.musician || @band.user_id == current_user.id
      @member_availability.destroy
      redirect_to edit_band_path(@band, anchor: "my-availabilities-list"), notice: "Availability removed."
    else
      redirect_to edit_band_path(@band, anchor: "my-availabilities-list"), alert: "You can only remove your own availability."
    end
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_member_availability
    @member_availability = @band.member_availabilities.find(params[:id])
  end

  def ensure_band_member
    unless current_user.musician && @band.musicians.include?(current_user.musician)
      redirect_to band_path(@band), alert: "You must be a band member to manage availability."
    end
  end

  def member_availability_params
    params.require(:member_availability).permit(:start_date, :end_date, :status, :notes)
  end
end
