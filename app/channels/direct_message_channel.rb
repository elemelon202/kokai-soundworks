class DirectMessageChannel < ApplicationCable::Channel
  def subscribed
    @chat = Chat.find(params[:chat_id])

    # Only allow participants to subscribe to the chat
    if @chat.users.include?(current_user)
      stream_from "chat_#{@chat.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
