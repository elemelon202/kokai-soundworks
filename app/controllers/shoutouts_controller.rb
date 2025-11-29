class ShoutoutsController < ApplicationController
  before_action :authenticate_user!

  def create
    @musician = Musician.find(params[:musician_id])
    @shoutout = @musician.shoutouts.build(shoutout_params)
    @shoutout.user = current_user
    skip_authorization

    if @shoutout.save
      Activity.track(user: current_user, action: :shoutout, trackable: @shoutout, musician: @musician)
      Notification.create_for_shoutout(@shoutout)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("shoutouts-#{@musician.id}", partial: "shoutouts/shoutouts_section", locals: { musician: @musician }) }
        format.html { redirect_back fallback_location: musician_path(@musician), notice: "Shoutout posted!" }
      end
    else
      redirect_back fallback_location: musician_path(@musician), alert: @shoutout.errors.full_messages.join(", ")
    end
  end

  def destroy
    @shoutout = Shoutout.find(params[:id])
    @musician = @shoutout.musician
    skip_authorization

    if @shoutout.user == current_user
      @shoutout.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("shoutouts-#{@musician.id}", partial: "shoutouts/shoutouts_section", locals: { musician: @musician }) }
        format.html { redirect_back fallback_location: musician_path(@musician), notice: "Shoutout removed." }
      end
    else
      redirect_back fallback_location: musician_path(@musician), alert: "You can't remove this shoutout."
    end
  end

  private

  def shoutout_params
    params.require(:shoutout).permit(:content)
  end
end
