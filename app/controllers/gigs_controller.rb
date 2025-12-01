class GigsController < ApplicationController

  skip_before_action :authenticate_user!, only: [:index, :show, :search, :new, :create, :edit, :update]

  def new
    @gig = Gig.new
    @venue = Venue.find(params[:venue_id])
    authorize @gig
  end

  def create
    @venue = Venue.find(params[:venue_id])
    @gig = Gig.new(gig_params)
    @gig.venue = @venue
    authorize @gig
    if @gig.save
      redirect_to edit_gig_path(@gig)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @gigs = Gig.all
    @venue = Venue.find(params[:venue_id])
    @gig.venue = @venue
  end

  def show
    @gig = Gig.find(params[:id])
    @venue = @gig.venue
    @booking = Booking.new
    authorize @gig
  end

  def edit
    @gig = Gig.find(params[:id])
    @booking = Booking.new
    authorize @gig
  end

  def update
     @gig = Gig.find(params[:id])
    authorize @gig
    if @gig.update(gig_params)
      redirect_to gig_path(@gig)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def gig_params
    params.require(:gig).permit(:name, :date, :start_time, :end_time)
  end

end
