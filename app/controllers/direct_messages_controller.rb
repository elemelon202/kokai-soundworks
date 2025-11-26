class DirectMessagesController < ApplicationController
  before_action :set_chat, only: [:show]
  before_action :set_recipient, only: [:create_or_show]
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    @chats = current_user.direct_message_chats
                        .includes(:users, messages: :user)
                        .order('messages.created_at DESC')
    authorize Chat
  end

  def show
    authorize @chat
    @messages = @chat.messages.includes(:user, :message_reads).order(created_at: :asc)

    # Mark messages as read
    @messages.each do |message|
      message_read = message.message_reads.find_or_create_by(user: current_user)
      message_read.update(read: true) unless message_read.read?
    end

    @message = Message.new
  end

  def create_or_show
    @chat = current_user.chat_with(@recipient)
    authorize @chat
    redirect_to direct_message_path(@chat)
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
    # Ensure it's a direct message and user is a participant
    unless @chat.direct_message? && @chat.users.include?(current_user)
      redirect_to root_path, alert: "Access denied"
    end
  end

  def set_recipient
    @recipient = User.find(params[:recipient_id])
  end
end
