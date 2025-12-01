class BookingsController < ApplicationController

  def new
    @booking = Booking.new
    @gig = Gig.find(params[:gig_id])
  end

  def create
    @gig = Gig.find(params[:gig_id])
    @booking = Booking.new(booking_params)
    @booking.gig = @gig
    authorize @booking
    if @booking.save
      redirect_to gig_path(@gig), notice: "Band booked!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy

  end

  private

  def set_gig
    @gig = Gig.find(params[:gig_id])
  end

  def booking_params
    params.require(:booking).permit(:band_id)
  end

end
