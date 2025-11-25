class MusiciansController < ApplicationController
  # find musician before performing show, edit, update, or destroy
  before_action :set_musician, only: [:show, :edit, :update, :destroy]

  def index
    # @musicians = Musician.all
    # see all musicians
    # singular musician
    # get that musicians bands / can do that with iteration
    #maybe have band name in card
    # Musician.new for create a profile button

    @musicians = policy_scope(Musician)
  end

  def show
    authorize @musician
    #should be able to see a musician
    @musician = Musician.find(params[:id])
    # should be able to see bands the musician is in
    @bands = @musician.bands
    # should have a chat button?
  end

  def new
    #create a profile?
    @musician = Musician.new
    authorize @musician
  end

  def create
    @musician = Musician.new(musician_params)
    @musician.user = current_user
    authorize @musician
    if @musician.save
      redirect to musician_path(@musician), notice: 'Profile has been created'
    else render :new, status: :unprocessable_entity
    end
  end

def edit
  authorize @musician
end

def update
  authorize @musician
  if @musician.update(musician_params)
    redirect_to musician_path(@musician), notice: 'Your profile has been updated'
  else
    render :edit, status: :unprocessable_entity
  end
end

  def destroy
    authorize @musician
    @musician = Musician.find(params[:id])
    redirect_to root_path, status: :see_other, notice: 'You have deleted your account. We hope to see you again'
    # if @musician.destroy
    #   redirect_to musicians_path status: :see_other, notice: 'You have deleted your profile!'
    # else
    #   redirect_to musicians_path, status: :unprocessable_entity, alert: 'Could not delete'
    # end
  end

  private

  def set_musician
    @musician = Musician.find(params[:id])
  end

  def musician_params
    params.require(:list).permit(:name, :photo)
  end

end
