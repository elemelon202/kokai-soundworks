# frozen_string_literal: true

class FundedGigApplicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_funded_gig
  before_action :set_application, only: [:approve, :reject]

  # GET /funded-gigs/:funded_gig_id/applications
  def index
    authorize @funded_gig.gig, :edit?
    skip_policy_scope

    @applications = @funded_gig.gig.gig_applications
                               .includes(band: [:follows, :musicians])
                               .order(mainstage_score_at_application: :desc)

    @pending_applications = @applications.pending
    @approved_applications = @applications.approved
    @rejected_applications = @applications.rejected
  end

  # PATCH /funded-gigs/:funded_gig_id/applications/:id/approve
  def approve
    authorize @application.gig, :edit?

    if @funded_gig.gig.bands.count >= @funded_gig.max_bands
      redirect_to funded_gig_applications_path(@funded_gig), alert: "Maximum bands (#{@funded_gig.max_bands}) already selected."
      return
    end

    ActiveRecord::Base.transaction do
      @application.update!(status: :approved)
      Booking.find_or_create_by!(gig: @funded_gig.gig, band: @application.band)
    end

    # Notify band
    @application.band.musicians.each do |musician|
      next unless musician.user
      Notification.create(
        user: musician.user,
        notification_type: 'funded_gig_application_approved',
        notifiable: @funded_gig,
        message: "#{@application.band.name} has been selected to play at #{@funded_gig.name}!",
        read: false
      )
    end

    redirect_to funded_gig_applications_path(@funded_gig), notice: "#{@application.band.name} approved!"
  end

  # PATCH /funded-gigs/:funded_gig_id/applications/:id/reject
  def reject
    authorize @application.gig, :edit?

    @application.update!(status: :rejected, response_message: params[:response_message])

    # Notify band
    @application.band.musicians.each do |musician|
      next unless musician.user
      Notification.create(
        user: musician.user,
        notification_type: 'funded_gig_application_rejected',
        notifiable: @funded_gig,
        message: "#{@application.band.name}'s application to #{@funded_gig.name} was not selected.",
        read: false
      )
    end

    redirect_to funded_gig_applications_path(@funded_gig), notice: "Application rejected."
  end

  private

  def set_funded_gig
    @funded_gig = FundedGig.find(params[:funded_gig_id])
  end

  def set_application
    @application = @funded_gig.gig.gig_applications.find(params[:id])
  end
end
