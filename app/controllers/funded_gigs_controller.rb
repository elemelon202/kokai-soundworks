# frozen_string_literal: true

class FundedGigsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_funded_gig, only: [:show, :edit, :update, :open_applications, :close_applications, :open_pledges, :process_funding, :cancel]
  before_action :set_gig_for_new, only: [:new, :create]

  # GET /funded-gigs
  def index
    @funded_gigs = FundedGig.includes(gig: [:venue, :bands])
                            .where(funding_status: [:open_for_applications, :accepting_pledges, :funded, :partially_funded])
                            .upcoming
                            .limit(20)

    skip_authorization
    skip_policy_scope
  end

  # GET /funded-gigs/:id
  def show
    skip_authorization
    @gig = @funded_gig.gig
    @pledges = @funded_gig.pledges.successful.includes(:user).order(created_at: :desc).limit(10)
    @user_pledge = current_user&.pledges&.find_by(funded_gig: @funded_gig)
    @user_ticket = current_user&.funded_gig_tickets&.find_by(funded_gig: @funded_gig)
  end

  # GET /venues/:venue_id/gigs/:gig_id/funded_gig/new
  def new
    @funded_gig = @gig.build_funded_gig(
      deadline_days_before: 7,
      max_bands: 3,
      allow_partial_funding: false,
      minimum_funding_percent: 80
    )
    authorize @funded_gig
  end

  # POST /venues/:venue_id/gigs/:gig_id/funded_gig
  def create
    @funded_gig = @gig.build_funded_gig(funded_gig_params)
    authorize @funded_gig

    if @funded_gig.save
      redirect_to funded_gig_path(@funded_gig), notice: "Funded gig created! Open applications when ready."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /funded-gigs/:id/edit
  def edit
    authorize @funded_gig
  end

  # PATCH /funded-gigs/:id
  def update
    authorize @funded_gig
    if @funded_gig.update(funded_gig_params)
      redirect_to funded_gig_path(@funded_gig), notice: "Funded gig updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # PATCH /funded-gigs/:id/open_applications
  def open_applications
    authorize @funded_gig, :update?

    unless @funded_gig.venue.stripe_connected?
      redirect_to funded_gig_path(@funded_gig), alert: "Please connect your Stripe account first."
      return
    end

    @funded_gig.update!(
      funding_status: :open_for_applications,
      applications_open_at: Time.current
    )

    # Notify bands about new opportunity
    NotifyBandsOfFundedGigJob.perform_later(@funded_gig.id)

    redirect_to funded_gig_path(@funded_gig), notice: "Applications are now open!"
  end

  # PATCH /funded-gigs/:id/close_applications
  def close_applications
    authorize @funded_gig, :update?
    @funded_gig.update!(applications_close_at: Time.current)
    redirect_to funded_gig_path(@funded_gig), notice: "Applications closed."
  end

  # PATCH /funded-gigs/:id/open_pledges
  def open_pledges
    authorize @funded_gig, :update?

    unless @funded_gig.gig.bands.any?
      redirect_to funded_gig_path(@funded_gig), alert: "Select bands before opening pledges."
      return
    end

    @funded_gig.update!(
      funding_status: :accepting_pledges,
      pledging_opens_at: Time.current
    )

    # Notify followers of selected bands
    NotifyFansOfFundedGigJob.perform_later(@funded_gig.id)

    redirect_to funded_gig_path(@funded_gig), notice: "Now accepting pledges!"
  end

  # PATCH /funded-gigs/:id/process_funding
  def process_funding
    authorize @funded_gig, :update?

    result = Stripe::FundedGigProcessingService.new(@funded_gig).process!(
      accept_partial: params[:accept_partial] == 'true'
    )

    if result[:success]
      redirect_to funded_gig_path(@funded_gig), notice: result[:message]
    else
      redirect_to funded_gig_path(@funded_gig), alert: result[:message]
    end
  end

  # DELETE /funded-gigs/:id/cancel
  def cancel
    authorize @funded_gig, :update?

    # Refund all pledges if any exist
    if @funded_gig.pledges.authorized.any?
      Stripe::FundedGigProcessingService.new(@funded_gig).process!(accept_partial: false)
    end

    @funded_gig.update!(funding_status: :cancelled)

    redirect_to venue_path(@funded_gig.venue), notice: "Funded gig cancelled. All pledges have been refunded."
  end

  private

  def set_funded_gig
    @funded_gig = FundedGig.find(params[:id])
  end

  def set_gig_for_new
    @gig = Gig.find(params[:gig_id])
  end

  def funded_gig_params
    params.require(:funded_gig).permit(
      :funding_target_cents, :currency, :deadline_days_before,
      :allow_partial_funding, :minimum_funding_percent,
      :venue_message, :max_bands
    )
  end
end
