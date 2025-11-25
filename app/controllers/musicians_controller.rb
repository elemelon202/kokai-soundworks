class MusiciansController < ApplicationController

  def index
    # see all musicians
    @musicians = Musician.all
    # singular musician
    # get that musicians bands / can do that with iteration
    #maybe have band name in card
    # Musician.new for create a profile button
  end

  def show
    #should be able to see a musician
    @musician = Musician.find(params[:id])
    # should be able to see bands the musician is in
    @bands = @musician.bands
    # should have a chat button?
  end

  def new
    #create a profile?
    @musician = Musician.new
  end

  def create
    @musician = Musician.new(musician_params)
    @musician.user = current_user
    if @musician.save
      redirect to musician_path(@musician)
    else render :new, status: :unprocessable_entity
    end
  end


  def destroy
    @musician = Musician.find(params[:id])
    if @musician.destroy
      redirect_to musicians_path status: :see_other, notice: 'You have deleted your profile!'
    else
      redirect_to musicians_path, status: :unprocessable_entity, alert: 'Could not delete'
    end
  end

  private

  def musician_params
    params.require(:list).permit(:name, :photo)
  end

end
