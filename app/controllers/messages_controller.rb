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

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "messages",
              partial: "messages/message",
              locals: { message: @message, current_user: current_user }
            ),
            turbo_stream.replace(
              "message_form",
              partial: "messages/form",
              locals: { chat: @chat, message: Message.new }
            )
          ]
        end
        format.html { redirect_to message_path(@chat) }
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
        format.html {
          @messages = @chat.messages.includes(:user).order(created_at: :asc)
          render "direct_messages/show", status: :unprocessable_entity
        }
      end
    end
  end

  def destroy
    authorize @message
    @message.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
      format.html { redirect_to chat_path(@chat), notice: "Message deleted." }
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
end
