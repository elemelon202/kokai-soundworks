class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat
  before_action :authorize_chat

  def index
    @messages = @chat ? @chat.messages.order(created_at: :asc) : Message.none
    @message = Message.new

    @unread_messages = @chat ? @chat.messages.joins(:message_reads).where(message_reads: { user_id: current_user.id, read: false }) : Message.none
    @unread_messages.each do |msg|
      msg_read = msg.message_reads.find_by(user: current_user)
      msg_read.update(read: true) if msg_read
    end
  end

  def create
    return unless @chat
    @message = @chat.messages.new(message_params)
    @message.user = current_user
    if @message.save
      redirect_to chat__messages_path(@chat)
    else
      flash.now[:alert] = "Failed to send message."
      render :index
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def authorize_chat
    unless @chat.users.include?(current_user)
      redirect_to root_path, alert: "You are not authorized to access this chat."
    end
  end
end
