class InvolvementsController < ApplicationController
  before_action :set_involvement, only: [:destroy]
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def destroy
    band = @involvement.band
    member_being_removed = @involvement.musician

    # Check if current user is the band leader
    is_band_leader = band.user_id == current_user.id

    # Don't allow the band leader to leave (they must delete or transfer ownership)
    if member_being_removed.user_id == current_user.id && is_band_leader
      redirect_to edit_band_path(band), alert: "As the band leader, you cannot leave the band. You must delete the band or transfer ownership first."
      return
    end

    # Allow removal if: current user is leaving OR current user is the band leader removing someone else
    unless member_being_removed.user_id == current_user.id || is_band_leader
      redirect_to edit_band_path(band), alert: "You are not authorized to remove this member."
      return
    end

    # Remove from band chat participation
    if band.chat
      Participation.find_by(user: member_being_removed.user, chat: band.chat)&.destroy
    end

    # Clean up any old invitations so they can be re-invited
    BandInvitation.where(band: band, musician: member_being_removed).destroy_all

    @involvement.destroy

    if member_being_removed.user_id == current_user.id
      redirect_to bands_path, notice: "You have left #{band.name}."
    else
      redirect_to edit_band_path(band), notice: "#{member_being_removed.name} has been removed from #{band.name}."
    end
  end

  private

  def set_involvement
    @involvement = Involvement.find(params[:id])
  end
end
