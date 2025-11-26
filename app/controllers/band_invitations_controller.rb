class BandInvitationsController < ApplicationController
  # Rails 7.1 requires these skips if the controller has no index action
  skip_after_action :verify_policy_scoped, raise: false
  skip_after_action :verify_authorized, raise: false

  before_action :set_band_invitation_by_token, only: [:accept, :decline]
  before_action :set_band, only: [:new, :create]
  before_action :fetch_pending_invitations, only: [:sent, :edit]

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
      @pending_invitations = policy_scope(BandInvitation).pending.sent_by(current_user)
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
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end



  def accept
    authorize @band_invitation
    @band_invitation.update(status: "Accepted")
    @band_invitation.band.musicians << @band_invitation.musician
    redirect_to band_path(@band_invitation.band), notice: "Invitation accepted."
  end

  def decline
    authorize @band_invitation
    @band_invitation.update(status: "Declined")
    redirect_to band_path(@band_invitation.band), notice: "Invitation declined."
  end

  def sent
    authorize BandInvitation
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

end
