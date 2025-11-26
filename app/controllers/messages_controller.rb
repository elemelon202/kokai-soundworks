class MessagesController < ApplicationController
  before_action :set_chat
  before_action :set_message, only: [:destroy]

  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user

    authorize @message

    if @message.save
      # Create message_reads for all participants except sender
      @chat.users.where.not(id: current_user.id).each do |user|
        @message.message_reads.create(user: user, read: false)
      end

      # Broadcast the message to all participants
      broadcast_message(@message)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/form",
            locals: { chat: @chat, message: Message.new }
          )
        end
        format.html { redirect_to direct_message_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          )
        end
        format.html do
          @messages = @chat.messages.includes(:user).order(created_at: :asc)
          render "direct_messages/show", status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    authorize @message
    @message.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
      format.html { redirect_to direct_message_path(@chat), notice: "Message deleted." }
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def set_message
    @message = @chat.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def broadcast_message(message)
    @chat.users.each do |user|
      ActionCable.server.broadcast(
        "chat_#{@chat.id}",
        {
          html: render_message_for_user(message, user),
          sender_id: current_user.id,
          user_id: user.id
        }
      )
    end
  end

  def render_message_for_user(message, user)
    ApplicationController.renderer.render(
      partial: "messages/message",
      locals: { message: message, current_user: user }
    )
  end
end
