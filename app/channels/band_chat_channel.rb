class BandChatChannel < ApplicationCable::Channel
  def subscribed
    @chat = Chat.find(params[:chat_id])
    # Only allow band members to subscribe
    if @chat.band && band_member?(@chat.band)
      stream_from "band_chat_#{@chat.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def band_member?(band)
    band.user_id == current_user.id ||
      (current_user.musician && band.musicians.include?(current_user.musician))
  end
end
