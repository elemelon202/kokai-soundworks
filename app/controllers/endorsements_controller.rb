class EndorsementsController < ApplicationController
  before_action :authenticate_user!

  def create
    @musician = Musician.find(params[:musician_id])
    @endorsement = @musician.endorsements.build(endorsement_params)
    @endorsement.user = current_user
    skip_authorization

    if @endorsement.save
      Activity.track(user: current_user, action: :endorse, trackable: @endorsement, musician: @musician)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("endorsements-#{@musician.id}", partial: "endorsements/endorsements_section", locals: { musician: @musician }) }
        format.html { redirect_back fallback_location: musician_path(@musician), notice: "Endorsement added!" }
      end
    else
      redirect_back fallback_location: musician_path(@musician), alert: @endorsement.errors.full_messages.join(", ")
    end
  end

  def destroy
    @endorsement = Endorsement.find(params[:id])
    @musician = @endorsement.musician
    skip_authorization

    if @endorsement.user == current_user
      @endorsement.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("endorsements-#{@musician.id}", partial: "endorsements/endorsements_section", locals: { musician: @musician }) }
        format.html { redirect_back fallback_location: musician_path(@musician), notice: "Endorsement removed." }
      end
    else
      redirect_back fallback_location: musician_path(@musician), alert: "You can't remove this endorsement."
    end
  end

  private

  def endorsement_params
    params.require(:endorsement).permit(:skill)
  end
end
