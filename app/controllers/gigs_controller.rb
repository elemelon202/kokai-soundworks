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
      redirect_to gig_path(@gig)
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

  def check_in
    @gig = Gig.find(params[:id])
    skip_authorization
    attendance = current_user.gig_attendances.find_or_initialize_by(gig: @gig)

    if @gig.date == Date.current
      attendance.update(status: :attended)
      respond_to do |format|
        format.turbo_stream { render_turbo_stream }
        format.html { redirect_back fallback_location: venues_path, notice: "Checked in to #{@gig.name}!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_turbo_stream }
        format.html { redirect_back fallback_location: venues_path, alert: "You can only check in on the day of the gig." }
      end
    end
  end

  def rsvp
    @gig = Gig.find(params[:id])
    skip_authorization
    attendance = current_user.gig_attendances.find_or_initialize_by(gig: @gig)

    if params[:status].blank?
      attendance.destroy if attendance.persisted?
    else
      attendance.update(status: params[:status])
    end

    respond_to do |format|
      format.turbo_stream { render_turbo_stream }
      format.html { redirect_back fallback_location: venues_path, notice: "RSVP updated!" }
    end
  end

  def discover
    skip_authorization
    @gigs = Gig.includes(:venue, :bands).where('date >= ?', Date.current).order(:date)

    if params[:city].present?
      @gigs = @gigs.joins(:venue).where(venues: {city: params[:city] })
    end
    if params[:following].present? && current_user
      followed_band_ids = current_user.followed_bands.pluck(:id)
      @gigs = @gigs.joins(:venue).where(bands: { id: followed_band_ids })
    end
    if params[:genre].present?
      @gigs = @gigs.joins(:bands).where("bands.genres ILIKE ?", "%#{params[:genre]}%")
    end
    @gigs = @gigs.distinct.limit(20)

    @cities = Venue.where.not(city:[nil, '']).distinct.pluck(:city).sort
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

  def render_turbo_stream
    render turbo_stream: turbo_stream.replace(
      "gig-attendance-#{@gig.id}",
      partial: "gig_attendances/buttons",
      locals: { gig: @gig }
    )
  end

  def gig_params
    params.require(:gig).permit(:name, :date, :start_time, :end_time, :poster, :ticket_price, :description, :genre)
  end

end
