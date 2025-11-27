class InvolvementsController < ApplicationController
  before_action :set_involvement, only: [:destroy]
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def destroy
    band = @involvement.band

    # Don't allow the band leader to leave
    if band.user_id == current_user.id
      redirect_to edit_band_path(band), alert: "As the band leader, you cannot leave the band. You must delete the band or transfer ownership first."
      return
    end

    # Ensure the current user is the one leaving
    unless @involvement.musician.user_id == current_user.id
      redirect_to edit_band_path(band), alert: "You can only remove yourself from a band."
      return
    end

    # Remove from band chat participation
    if band.chat
      Participation.find_by(user: current_user, chat: band.chat)&.destroy
    end

    @involvement.destroy
    redirect_to bands_path, notice: "You have left #{band.name}."
  end

  private

  def set_involvement
    @involvement = Involvement.find(params[:id])
  end
end
