class VenuesController < ApplicationController

  def index
    @venues = Venue.all
  end

  def show
    @venue = Venue.find(params[:id])
  end

  def new
    @venue = Venue.new
  end

  def create
    @venue = Venue.new(venue_params)
    if @venue.save
      redirect_to venues_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @venue = Venue.find(params[:id])
  end

  def update
    @venue = Venue.find(params[:id])
    if @venue.update(venue_params)
      redirect_to venue_path(@venue)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @venue = Venue.find(params[:id])
    @venue.destroy
    redirect_to venues_path, status: :see_other
  end

  private

  def venue_params
    params.require(:venue).permit(:name, :address, :city, :capacity, :description)
  end

end
