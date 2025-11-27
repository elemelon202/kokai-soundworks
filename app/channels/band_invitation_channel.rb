class BandInvitationChannel < ApplicationCable::Channel
  def subscribed
    band = Band.find(params[:band_id])
    # Allow band owner or any band member to subscribe
    if band.user_id == current_user.id || band_member?(band)
      stream_from "band_invitations_#{params[:band_id]}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def band_member?(band)
    current_user.musician && band.musicians.include?(current_user.musician)
  end
end
