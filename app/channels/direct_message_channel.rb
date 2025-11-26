class DirectMessageChannel < ApplicationCable::Channel
  def subscribed
    @chat = Chat.find(params[:chat_id])
    stream_from "chat_#{@chat.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
