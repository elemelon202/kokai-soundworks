# frozen_string_literal: true

class PledgesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_funded_gig
  before_action :set_pledge, only: [:show, :cancel]

  # GET /funded-gigs/:funded_gig_id/pledges/new
  def new
    @pledge = @funded_gig.pledges.build
    authorize @pledge

    unless @funded_gig.can_accept_pledges?
      redirect_to funded_gig_path(@funded_gig), alert: "This gig is not accepting pledges."
    end
  end

  # POST /funded-gigs/:funded_gig_id/pledges
  def create
    # Check if user already pledged
    existing_pledge = @funded_gig.pledges.find_by(user: current_user)
    if existing_pledge
      redirect_to funded_gig_path(@funded_gig), alert: "You've already pledged to this gig."
      return
    end

    @pledge = @funded_gig.pledges.build(pledge_params)
    @pledge.user = current_user
    authorize @pledge

    result = Stripe::PledgeCreationService.new(@pledge).create!

    if result[:success]
      redirect_to result[:checkout_url], allow_other_host: true
    else
      flash.now[:alert] = result[:error]
      render :new, status: :unprocessable_entity
    end
  end

  # GET /funded-gigs/:funded_gig_id/pledges/confirm (Stripe redirect)
  def confirm
    session_id = params[:session_id]

    unless session_id
      redirect_to funded_gig_path(@funded_gig), alert: "Invalid confirmation."
      return
    end

    result = Stripe::PledgeConfirmationService.new(session_id).confirm!

    if result[:success]
      redirect_to funded_gig_path(@funded_gig), notice: "Thank you for your pledge! You'll receive your free ticket once the gig is fully funded."
    else
      redirect_to funded_gig_path(@funded_gig), alert: result[:error]
    end
  end

  # GET /funded-gigs/:funded_gig_id/pledges/:id
  def show
    authorize @pledge
  end

  # DELETE /funded-gigs/:funded_gig_id/pledges/:id/cancel
  def cancel
    authorize @pledge

    if @pledge.authorized? && @funded_gig.can_accept_pledges?
      begin
        Stripe::PaymentIntent.cancel(@pledge.stripe_payment_intent_id)
        @pledge.update!(status: :refunded, refunded_at: Time.current, refund_reason: 'user_requested')
        redirect_to funded_gig_path(@funded_gig), notice: "Your pledge has been cancelled."
      rescue Stripe::StripeError => e
        redirect_to funded_gig_path(@funded_gig), alert: "Unable to cancel pledge: #{e.message}"
      end
    else
      redirect_to funded_gig_path(@funded_gig), alert: "Cannot cancel this pledge."
    end
  end

  # GET /my-pledges
  def my_pledges
    skip_before_action :set_funded_gig
    @pledges = current_user.pledges.includes(funded_gig: { gig: :venue }).order(created_at: :desc)
    skip_authorization
  end

  private

  def set_funded_gig
    @funded_gig = FundedGig.find(params[:funded_gig_id])
  end

  def set_pledge
    @pledge = @funded_gig.pledges.find(params[:id])
  end

  def pledge_params
    params.require(:pledge).permit(:amount_cents, :fan_message, :anonymous)
  end
end
