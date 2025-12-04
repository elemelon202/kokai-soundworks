# frozen_string_literal: true

class VenueStripeAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_venue

  # GET /venues/:venue_id/stripe_account/new
  def new
    authorize @venue, :edit?

    if @venue.venue_stripe_account.present?
      redirect_to onboarding_venue_stripe_account_path(@venue)
      return
    end
  end

  # POST /venues/:venue_id/stripe_account
  def create
    authorize @venue, :edit?

    result = Stripe::ConnectService.new(@venue).create_account!

    if result[:success]
      redirect_to result[:onboarding_url], allow_other_host: true
    else
      redirect_to edit_venue_path(@venue), alert: "Failed to create Stripe account: #{result[:error]}"
    end
  end

  # GET /venues/:venue_id/stripe_account/onboarding
  def onboarding
    authorize @venue, :edit?

    result = Stripe::ConnectService.new(@venue).create_onboarding_link!

    if result[:success]
      redirect_to result[:url], allow_other_host: true
    else
      redirect_to edit_venue_path(@venue), alert: "Failed to create onboarding link: #{result[:error]}"
    end
  end

  # GET /venues/:venue_id/stripe_account/return (Stripe redirect)
  def return
    authorize @venue, :edit?

    Stripe::ConnectService.new(@venue).refresh_account_status!

    if @venue.stripe_connected?
      redirect_to edit_venue_path(@venue), notice: "Stripe account connected! You can now create funded gigs."
    else
      redirect_to edit_venue_path(@venue), alert: "Please complete your Stripe account setup to receive payments."
    end
  end

  # GET /venues/:venue_id/stripe_account/refresh
  def refresh
    authorize @venue, :edit?
    redirect_to onboarding_venue_stripe_account_path(@venue)
  end

  private

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end
end
