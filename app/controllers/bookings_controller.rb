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
    @booking = Booking.find(params[:id])
    authorize @booking
    @booking.destroy
    redirect_to gig_path(@booking.gig), notice: "Band removed."
  end

  private

  def set_gig
    @gig = Gig.find(params[:gig_id])
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:band_id)
  end

end
