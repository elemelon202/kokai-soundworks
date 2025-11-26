class BandsController < ApplicationController
  # I added a bands policy so I edited some of the functions (marked with a star)
  # added skip_before_action so public users can see these pages.
  skip_before_action :authenticate_user!, only: [:index, :show]
  # before_action :authenticate_user! - **Tyrhen edited this out so it doesn't override line 4**
  before_action :set_band, only: [:show, :edit, :update, :destroy]
  before_action :authorize_band, only: [:edit, :update, :destroy]

  def index
    @bands = policy_scope(Band) #<--- This is all you need for the index to bypass pundit - Tyrhen
    @bands = Band.all

     if params[:genres].present?
    @bands = Band.with_genres(params[:genres])
     end
      if params[:q].present?
    @bands = @bands.where("name ILIKE ?", "%#{params[:q]}%")
      end
  end
  def show
    authorize @band
  end
  def new
    @band = Band.new
    authorize @band #* Tyrhen was here
  end
  def create
    @band = Band.new(band_params)
    @band.user = current_user
    authorize @band #* Tyrhen was here
    if @band.save
      redirect_to band_path(@band)
    else
      render :new
    end
  end
  def edit
    authorize @band #* Tyrhen was here
    @pending_bookings = @band.bookings.where(status: 'pending')
    # app/controllers/bands_controller.rb
  @chat = @band.chat || @band.create_band_chat(name: "#{@band.name} Chat")

  # All messages for the chat
  @messages = @chat.messages.order(created_at: :asc)

  # Unread messages for current_user
  @unread_messages = @chat.messages.joins(:message_reads)
                           .where(message_reads: { user_id: current_user.id, read: false })

  # Mark unread messages as read
  @unread_messages.each do |msg|
    msg_read = msg.message_reads.find_by(user: current_user)
    msg_read.update(read: true) if msg_read
    end
  end
  def update
    authorize @band #* Tyrhen was here
    if @band.update(band_params)
      redirect_to band_path(@band)
    else
      render :edit
    end
  end
  def destroy
    authorize @band #* Tyrhen was here
    @band.destroy
    redirect_to bands_path
  end

  private
  def band_params
    params.require(:band).permit(:name, :description, genre_list: [], musician_ids: [])
  end
  def set_band
    @band = Band.find(params[:id])
  end
  def authorize_band
    unless @band.user == current_user
      redirect_to bands_path, alert: "You are not authorized to perform this action."
    end
  end
end
