require 'rails_helper'

RSpec.describe "BandInvitations", type: :request do
  let(:band_owner) { create(:user) }
  let(:band) { create(:band, user: band_owner) }
  let(:invitee_user) { create(:user) }
  let(:invitee_musician) { create(:musician, user: invitee_user) }

  describe "POST /bands/:band_id/band_invitations" do
    context "when not logged in" do
      it "redirects to login" do
        post band_band_invitations_path(band), params: { band_invitation: { musician_id: invitee_musician.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as band owner" do
      before { sign_in band_owner }

      it "creates a new invitation" do
        expect {
          post band_band_invitations_path(band), params: { band_invitation: { musician_id: invitee_musician.id } }
        }.to change(BandInvitation, :count).by(1)
      end

      it "sets the inviter to the current user" do
        post band_band_invitations_path(band), params: { band_invitation: { musician_id: invitee_musician.id } }
        expect(BandInvitation.last.inviter).to eq(band_owner)
      end

      it "sets the status to Pending" do
        post band_band_invitations_path(band), params: { band_invitation: { musician_id: invitee_musician.id } }
        expect(BandInvitation.last.status).to eq("Pending")
      end
    end
  end

  describe "GET /accept_invitation/:token" do
    let!(:invitation) { create(:band_invitation, band: band, musician: invitee_musician, inviter: band_owner) }

    context "when not logged in" do
      it "redirects to login" do
        get accept_band_invitation_path(token: invitation.token)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as the invited musician" do
      before { sign_in invitee_user }

      it "accepts the invitation" do
        get accept_band_invitation_path(token: invitation.token)
        expect(invitation.reload.status).to eq("Accepted")
      end

      it "adds the musician to the band" do
        get accept_band_invitation_path(token: invitation.token)
        expect(band.reload.musicians).to include(invitee_musician)
      end

      it "redirects to the band page" do
        get accept_band_invitation_path(token: invitation.token)
        expect(response).to redirect_to(band_path(band))
      end

      it "shows a success flash message" do
        get accept_band_invitation_path(token: invitation.token)
        expect(flash[:notice]).to eq("Invitation accepted.")
      end
    end

    context "when logged in as a different user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with unauthorized message" do
        get accept_band_invitation_path(token: invitation.token)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /decline_invitation/:token" do
    let!(:invitation) { create(:band_invitation, band: band, musician: invitee_musician, inviter: band_owner) }

    context "when logged in as the invited musician" do
      before { sign_in invitee_user }

      it "declines the invitation" do
        get decline_band_invitation_path(token: invitation.token)
        expect(invitation.reload.status).to eq("Declined")
      end

      it "does not add the musician to the band" do
        get decline_band_invitation_path(token: invitation.token)
        expect(band.musicians).not_to include(invitee_musician)
      end

      it "redirects to the band page" do
        get decline_band_invitation_path(token: invitation.token)
        expect(response).to redirect_to(band_path(band))
      end

      it "shows a flash message" do
        get decline_band_invitation_path(token: invitation.token)
        expect(flash[:notice]).to eq("Invitation declined.")
      end
    end
  end
end
