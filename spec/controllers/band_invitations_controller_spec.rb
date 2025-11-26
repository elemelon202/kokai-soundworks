# spec/controllers/band_invitations_controller_spec.rb
require 'rails_helper'

RSpec.describe BandInvitationsController, type: :controller do
  # Include Devise helpers for controller tests
  include Devise::Test::ControllerHelpers

  let(:user) { User.create!(email: "user@example.com", password: "password", username: "user123") }
  let(:musician) { Musician.create!(user: user, name: "John Doe", instrument: "Guitar", styles: "Rock", location: "NYC", bio: "Test bio") }
  let(:band) { Band.create!(name: "Test Band", user: user) }
  let(:inviter) { user }  # user sending the invite
  let(:invitee_user) { User.create!(email: "invitee@example.com", password: "password") }
  let(:invitee_musician) { Musician.create!(user: invitee_user, name: "Jane Smith", instrument: "Bass", styles: "Jazz", location: "LA", bio: "Test bio") }
  let!(:band_invitation) do
    BandInvitation.create!(
      band: band,
      inviter: inviter,
      musician: invitee_musician,
      status: "Pending",
      token: SecureRandom.hex(20)
    )
  end

  before do
    sign_in invitee_user
  end

  describe "GET #accept" do
    it "accepts the invitation, adds musician to band, and updates status" do
      get :accept, params: { token: band_invitation.token }

      band_invitation.reload  # reload from DB to see changes
      expect(band_invitation.status).to eq("Accepted")
      expect(band.musicians).to include(invitee_musician)
      expect(response).to redirect_to(band_path(band))
      expect(flash[:notice]).to eq("Invitation accepted.")
    end
  end

  describe "GET #decline" do
    it "declines the invitation and updates status" do
      get :decline, params: { token: band_invitation.token }

      band_invitation.reload
      expect(band_invitation.status).to eq("Declined")
      expect(response).to redirect_to(band_path(band))
      expect(flash[:notice]).to eq("Invitation declined.")
    end
  end
end
