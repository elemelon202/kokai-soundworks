class VenuesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_venue, only: [:show, :edit, :update, :destroy]

  def index
    @venues = policy_scope(Venue).all.order(:name)

    if user_signed_in? && current_user.musician.present?
      musician = current_user.musician
      user_band_ids = musician.bands.pluck(:id)

      # Get venues the current user has played at through their bands
      @played_venues = Venue.joins(gigs: :bookings)
                            .where(bookings: { band_id: user_band_ids })
                            .distinct
    else
      @played_venues = Venue.none
    end

    # Show all venues to everyone (no filtering)
    @recommended_venues = policy_scope(Venue).order(:name)
  end

  def show
    authorize @venue
    @gigs = @venue.gigs
  end

  def new
    @venue = Venue.new
    authorize @venue
  end

  def create
    @venue = Venue.new(venue_params)
    @venue.user = current_user
    authorize @venue
    if @venue.save
      redirect_to venue_path(@venue) #edited by Tyrhen
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @venue
    @gig = Gig.new
    @booking = Booking.new
  end

  def update
    authorize @venue
    if @venue.update(venue_params)
      redirect_to venue_path(@venue)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @venue
    @venue.destroy
    redirect_to venues_path, status: :see_other
  end

  private

  def set_venue
    @venue = Venue.find(params[:id])
  end

  def venue_params
    params.require(:venue).permit(:name, :address, :city, :capacity, :description, :banner, :banner_position, photos: [])
  end

  def purge_photo
    @venue = Venue.find(params[:id])
    authorize @venue
    photo = @venue.photos.find(params[:photo_id])
    photo.purge
    redirect_to edit_venue_path(@venue), notice: "Photo removed successfully."
  end
end
