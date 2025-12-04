# frozen_string_literal: true

class FundedGigChannel < ApplicationCable::Channel
  def subscribed
    @funded_gig = FundedGig.find(params[:funded_gig_id])
    stream_from "funded_gig_#{@funded_gig.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
