class BandGigsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_band
  before_action :set_band_gig, only: [:destroy]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def create
    @band_gig = @band.band_gigs.build(band_gig_params)

    if @band_gig.save
      redirect_to edit_band_path(@band), notice: "Gig added!"
    else
      redirect_to edit_band_path(@band), alert: "Could not add gig: #{@band_gig.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @band_gig.destroy
    redirect_to edit_band_path(@band), notice: "Gig removed."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_band_gig
    @band_gig = @band.band_gigs.find(params[:id])
  end

  def band_gig_params
    params.require(:band_gig).permit(:name, :venue_name, :date, :location, :notes)
  end
end
