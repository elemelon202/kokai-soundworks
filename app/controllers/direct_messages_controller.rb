class DirectMessagesController < ApplicationController
  before_action :set_chat, only: [:show, :destroy]
  before_action :set_recipient, only: [:create_or_show]
  before_action :load_sidebar_chats, only: [:index, :show]
  skip_after_action :verify_policy_scoped, only: [:index, :show, :destroy]

  def index
    authorize Chat
    @musicians = Musician.where.not(user_id: current_user.id).includes(:user)
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
    @musicians = Musician.where.not(user_id: current_user.id).includes(:user)
  end

  def create_or_show
    if @recipient == current_user
      skip_authorization
      redirect_to root_path, alert: "You cannot message yourself"
      return
    end

    @chat = current_user.chat_with(@recipient)
    authorize @chat
    redirect_to direct_message_path(@chat)
  end

  def destroy
    authorize @chat, :destroy?
    @chat.destroy
    redirect_to direct_messages_path, notice: "Conversation deleted."
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

  def load_sidebar_chats
    @chats = current_user.direct_message_chats
                        .includes(:users, messages: :user)
                        .order('messages.created_at DESC')
  end
end
