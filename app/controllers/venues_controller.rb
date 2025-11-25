class VenuesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @venues = policy_scope(Venue).all
  end

  def show
    @venue = Venue.find(params[:id])
    authorize @venue
  end

  def new
    @venue = Venue.new
  end

  def create
    @venue = Venue.new(venue_params)
    @venue.user = current_user
    authorize @venue
    if @venue.save
      redirect_to venues_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @venue
    @venue = Venue.find(params[:id])
  end

  def update
    authorize @venue
    @venue = Venue.find(params[:id])
    if @venue.update(venue_params)
      redirect_to venue_path(@venue)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @venue
    @venue = Venue.find(params[:id])
    @venue.destroy
    redirect_to venues_path, status: :see_other
  end

  private

  def venue_params
    params.require(:venue).permit(:name, :address, :city, :capacity, :description, photos: [])
  end

end
