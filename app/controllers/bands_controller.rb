class BandsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_band, only: [:show, :edit, :update, :destroy]
  before_action :authorize_band, only: [:edit, :update, :destroy]

  def index
    @bands = Band.all

     if params[:genres].present?
    @bands = Band.with_genres(params[:genres])
     end
      if params[:q].present?
    @bands = @bands.where("name ILIKE ?", "%#{params[:q]}%")
      end
  end
  def show
  end
  def new
    @band = Band.new
  end
  def create
    @band = Band.new(band_params)
    @band.user = current_user
    if @band.save
      redirect_to band_path(@band)
    else
      render :new
    end
  end
  def edit
  end
  def update
    if @band.update(band_params)
      redirect_to band_path(@band)
    else
      render :edit
    end
  end
  def destroy
    @band.destroy
    redirect_to bands_path
  end

  private
  def band_params
    params.require(:band).permit(:name, :description, genre_list: [])
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
