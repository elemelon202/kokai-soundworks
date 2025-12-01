class VenuesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_venue, only: [:show, :edit, :update, :destroy]

  def index
    @venues = policy_scope(Venue).all

    if user_signed_in? && current_user.musician.present?
      musician = current_user.musician
      user_band_ids = musician.bands.pluck(:id)

      # Get venues the current user has played at through their bands
      @played_venues = Venue.joins(gigs: :bookings)
                            .where(bookings: { band_id: user_band_ids })
                            .distinct

      # Recommended venues: prioritize by location match and capacity
      # TODO: Factor in fan_count when fans model is added
      # For now, we use follower count as a proxy for popularity
      fan_count = musician.followers.count

      # Determine ideal venue capacity range based on fan count
      # Small acts (< 100 fans) -> venues up to 200 capacity
      # Medium acts (100-500 fans) -> venues 100-500 capacity
      # Larger acts (500+ fans) -> venues 300+ capacity
      min_capacity = fan_count > 100 ? (fan_count * 0.5).to_i : 0
      max_capacity = fan_count > 500 ? nil : [fan_count * 3, 200].max

      user_location = musician.location&.downcase&.strip

      # Build recommended venues query
      recommended = policy_scope(Venue)

      if max_capacity
        recommended = recommended.where("capacity <= ?", max_capacity)
      end
      if min_capacity > 0
        recommended = recommended.where("capacity >= ?", min_capacity)
      end

      # Order by: same city first, then by capacity (smaller first for smaller acts)
      if user_location.present?
        @recommended_venues = recommended.order(
          Arel.sql("CASE WHEN LOWER(city) = #{ActiveRecord::Base.connection.quote(user_location)} THEN 0 ELSE 1 END"),
          :capacity
        )
      else
        @recommended_venues = recommended.order(:capacity)
      end
    else
      @played_venues = Venue.none
      @recommended_venues = policy_scope(Venue).order(:capacity)
    end
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
