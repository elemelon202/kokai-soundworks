class MessagesController < ApplicationController
  before_action :set_chat

  def index
    authorize Message.new(chat: @chat)
    @messages = @chat.messages.order(created_at: :asc)
  end

  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user

    authorize @message

    if @message.save
      redirect_to chat_messages_path(@chat)
    else
      flash.now[:alert] = "Failed to send message."
      render :index
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
