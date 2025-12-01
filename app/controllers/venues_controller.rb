class VenuesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_venue, only: [:show, :edit, :update, :destroy]

  def index
    @venues = policy_scope(Venue).all
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
    params.require(:venue).permit(:name, :address, :city, :capacity, :description, photos: [])
  end
end
