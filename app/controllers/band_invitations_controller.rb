class BandInvitationsController < ApplicationController
  # Rails 7.1 requires these skips if the controller has no index action
  skip_after_action :verify_policy_scoped, raise: false
  skip_after_action :verify_authorized, raise: false

  before_action :set_band_invitation_by_token, only: [:accept, :decline]
  before_action :set_band, only: [:new, :create]
  before_action :fetch_pending_invitations, only: [:sent]

  respond_to :html, :turbo_stream


  def new
    @band_invitation = @band.band_invitations.new
    authorize @band_invitation
  end

def create
  @band_invitation = BandInvitation.new(band_invitation_params)
  @band_invitation.band = @band
  @band_invitation.inviter = current_user
  @band_invitation.status = "Pending"
  @band_invitation.token = SecureRandom.hex(20)

  authorize @band_invitation

  respond_to do |format|
    if @band_invitation.save
      # Create notification for the invited musician
      Notification.create_for_band_invitation(@band_invitation)

      # Get all pending invitations for this band (not just current user's)
      @pending_invitations = @band.band_invitations.pending
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "band_invitation_form",
            partial: "bands/invite",
            locals: { band: @band, invitation: BandInvitation.new }
          ),
          turbo_stream.update(
            "flash_messages",
            partial: "shared/flash",
            locals: { notice: "Invitation sent successfully.", alert: nil }
          ),
          turbo_stream.replace(
            "pending_invitations_list",
            partial: "bands/pending_invitations",
            locals: { pending_invitations: @pending_invitations }
          )
        ]
      end
      format.html { redirect_to band_path(@band), notice: "Invitation sent successfully." }
    else
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "band_invitation_form",
            partial: "bands/invite",
            locals: { band: @band, invitation: @band_invitation }
          ),
          turbo_stream.update(
            "flash_messages",
            partial: "shared/flash",
            locals: { notice: nil, alert: @band_invitation.errors.full_messages.to_sentence }
          )
        ]
      end
      format.html { redirect_to edit_band_path(@band), alert: @band_invitation.errors.full_messages.to_sentence }
    end
  end
end



  def accept
    authorize @band_invitation

    # Check if invitation was already accepted
    if @band_invitation.status == "Accepted"
      redirect_to band_path(@band_invitation.band), notice: "You have already accepted this invitation."
      return
    end

    @band_invitation.update(status: "Accepted")

    # Only add musician to band if they're not already a member
    unless @band_invitation.band.musicians.include?(@band_invitation.musician)
      @band_invitation.band.musicians << @band_invitation.musician

      # Notify the inviter that invitation was accepted
      Notification.create_for_invitation_response(@band_invitation, accepted: true)
      # Notify band members about new member
      Notification.create_for_band_member_joined(@band_invitation.band, @band_invitation.musician)
    end

    broadcast_invitation_update(@band_invitation)
    redirect_to band_path(@band_invitation.band), notice: "Invitation accepted."
  end

  def decline
    authorize @band_invitation
    @band_invitation.update(status: "Declined")

    # Notify the inviter that invitation was declined
    Notification.create_for_invitation_response(@band_invitation, accepted: false)

    broadcast_invitation_update(@band_invitation)
    redirect_to band_path(@band_invitation.band), notice: "Invitation declined."
  end

  def sent
    authorize BandInvitation
  end

  def destroy
    @band = Band.find(params[:band_id])
    @band_invitation = @band.band_invitations.find(params[:id])
    authorize @band_invitation

    @band_invitation.destroy
    @pending_invitations = @band.band_invitations.pending

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "pending_invitations_list",
            partial: "bands/pending_invitations",
            locals: { pending_invitations: @pending_invitations }
          ),
          turbo_stream.update(
            "flash_messages",
            partial: "shared/flash",
            locals: { notice: "Invitation cancelled.", alert: nil }
          )
        ]
      end
      format.html { redirect_to edit_band_path(@band), notice: "Invitation cancelled." }
    end
  end


  def band_invitation_params
    params.require(:band_invitation).permit(:musician_id)
  end

  def set_band_invitation_by_token
    @band_invitation = BandInvitation.find_by(token: params[:token])
    unless @band_invitation
      redirect_to root_path, alert: "Invitation not found."
    end
  end

  def set_band
    @band = Band.find(params[:band_id])
  end

  def fetch_pending_invitations
    @pending_invitations = policy_scope(BandInvitation).pending.sent_by(current_user)
  end

  def broadcast_invitation_update(invitation)
    band = invitation.band
    # Show all pending invitations for this band (visible to all band members)
    pending_invitations = band.band_invitations.pending

    ActionCable.server.broadcast(
      "band_invitations_#{band.id}",
      {
        type: "invitation_updated",
        html: ApplicationController.render(
          partial: "bands/pending_invitations",
          locals: { pending_invitations: pending_invitations }
        ),
        member_count: band.musicians.count
      }
    )
  end
end
