class GigApplicationsController < ApplicationController
  before_action :set_gig_application, only: [:approve, :reject]

  # Venue owner sees applications for their gigs
  def index
    authorize GigApplication
    skip_policy_scope
    @pending = GigApplication.joins(gig: :venue)
                             .where(venues: { user_id: current_user.id }, status: :pending)
                             .includes(:band, gig: :venue)
    @processed = GigApplication.joins(gig: :venue)
                               .where(venues: { user_id: current_user.id })
                               .where.not(status: :pending)
                               .includes(:band, gig: :venue)
                               .order(updated_at: :desc)
                               .limit(20)
  end

  # Band applies to a gig
  def create
    @gig = Gig.find(params[:gig_id])
    @application = @gig.gig_applications.build(gig_application_params)
    @application.band = current_user.led_bands.find(params[:gig_application][:band_id])
    authorize @application

    if @application.save
      redirect_to @gig, notice: "Application submitted!"
    else
      redirect_to @gig, alert: @application.errors.full_messages.join(", ")
    end
  end

  def approve
    authorize @application
    @application.update(status: :approved)

    # Add band to gig via Booking
    Booking.find_or_create_by(gig: @application.gig, band: @application.band)

    redirect_to gig_applications_path, notice: "Application approved! #{@application.band.name} added to gig."
  end

  def reject
    authorize @application
    @application.update(status: :rejected, response_message: params[:response_message])

    redirect_to gig_applications_path, notice: "Application rejected."
  end

  private

  def set_gig_application
    @application = GigApplication.find(params[:id])
  end

  def gig_application_params
    params.require(:gig_application).permit(:message, :band_id)
  end
end
