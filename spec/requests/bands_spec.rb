require 'rails_helper'

RSpec.describe "Bands", type: :request do
  describe "GET /bands" do
    let!(:band1) { create(:band) }
    let!(:band2) { create(:band) }

    it "returns a successful response" do
      get bands_path
      expect(response).to have_http_status(:success)
    end

    it "displays all bands" do
      get bands_path
      expect(response.body).to include(band1.name)
      expect(response.body).to include(band2.name)
    end

    context "with genre filter" do
      before do
        band1.genre_list.add("Rock")
        band1.save
        band2.genre_list.add("Jazz")
        band2.save
      end

      it "filters bands by genre" do
        get bands_path, params: { genres: ["Rock"] }
        expect(response.body).to include(band1.name)
      end
    end

    context "with name search" do
      let!(:band1) { create(:band, name: "The Beatles") }
      let!(:band2) { create(:band, name: "The Rolling Stones") }

      it "filters bands by name" do
        get bands_path, params: { name: "Beatles" }
        expect(response.body).to include("The Beatles")
      end
    end
  end

  describe "GET /bands/:id" do
    let(:band) { create(:band) }

    it "returns a successful response" do
      get band_path(band)
      expect(response).to have_http_status(:success)
    end

    it "displays the band details" do
      get band_path(band)
      expect(response.body).to include(band.name)
    end
  end

  describe "GET /bands/new" do
    context "when not logged in" do
      it "redirects to login" do
        get new_band_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "returns a successful response" do
        get new_band_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /bands" do
    context "when not logged in" do
      it "redirects to login" do
        post bands_path, params: { band: { name: "New Band" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "creates a new band" do
        expect {
          post bands_path, params: { band: { name: "New Band", description: "A new band" } }
        }.to change(Band, :count).by(1)
      end

      it "redirects to the new band" do
        post bands_path, params: { band: { name: "New Band", description: "A new band" } }
        expect(response).to redirect_to(band_path(Band.last))
      end
    end
  end

  describe "GET /bands/:id/edit" do
    let(:owner) { create(:user) }
    let(:band) { create(:band, user: owner) }

    context "when not logged in" do
      it "redirects to login" do
        get edit_band_path(band)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as owner" do
      before { sign_in owner }

      it "returns a successful response" do
        get edit_band_path(band)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as band member (non-owner)" do
      let(:member_user) { create(:user) }
      let(:member_musician) { create(:musician, user: member_user) }

      before do
        create(:involvement, band: band, musician: member_musician)
        sign_in member_user
      end

      it "returns a successful response" do
        get edit_band_path(band)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as non-member" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with unauthorized message" do
        get edit_band_path(band)
        expect(response).to redirect_to(bands_path)
      end
    end
  end

  describe "PATCH /bands/:id" do
    let(:owner) { create(:user) }
    let(:band) { create(:band, user: owner) }

    context "when logged in as owner" do
      before { sign_in owner }

      it "updates the band" do
        patch band_path(band), params: { band: { name: "Updated Name" } }
        expect(band.reload.name).to eq("Updated Name")
      end

      it "redirects to the band" do
        patch band_path(band), params: { band: { name: "Updated Name" } }
        expect(response).to redirect_to(band_path(band))
      end
    end

    context "when logged in as band member (non-owner)" do
      let(:member_user) { create(:user) }
      let(:member_musician) { create(:musician, user: member_user) }

      before do
        create(:involvement, band: band, musician: member_musician)
        sign_in member_user
      end

      it "updates the band" do
        patch band_path(band), params: { band: { name: "Member Updated" } }
        expect(band.reload.name).to eq("Member Updated")
      end

      it "redirects to the band" do
        patch band_path(band), params: { band: { name: "Member Updated" } }
        expect(response).to redirect_to(band_path(band))
      end
    end

    context "when logged in as non-member" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not update the band" do
        original_name = band.name
        patch band_path(band), params: { band: { name: "Unauthorized Update" } }
        expect(band.reload.name).to eq(original_name)
      end

      it "redirects with unauthorized message" do
        patch band_path(band), params: { band: { name: "Unauthorized Update" } }
        expect(response).to redirect_to(bands_path)
      end
    end
  end

  describe "DELETE /bands/:id" do
    let(:owner) { create(:user) }
    let!(:band) { create(:band, user: owner) }

    context "when logged in as owner" do
      before { sign_in owner }

      it "destroys the band" do
        expect {
          delete band_path(band)
        }.to change(Band, :count).by(-1)
      end

      it "redirects to bands index" do
        delete band_path(band)
        expect(response).to redirect_to(bands_path)
      end
    end

    context "when logged in as band member (non-owner)" do
      let(:member_user) { create(:user) }
      let(:member_musician) { create(:musician, user: member_user) }

      before do
        create(:involvement, band: band, musician: member_musician)
        sign_in member_user
      end

      it "does not destroy the band" do
        expect {
          delete band_path(band)
        }.not_to change(Band, :count)
      end

      it "redirects with unauthorized message" do
        delete band_path(band)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as non-member" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not destroy the band" do
        expect {
          delete band_path(band)
        }.not_to change(Band, :count)
      end

      it "redirects with unauthorized message" do
        delete band_path(band)
        expect(response).to redirect_to(bands_path)
      end
    end
  end

  describe "PATCH /bands/:id/transfer_leadership" do
    let(:owner) { create(:user) }
    let(:band) { create(:band, user: owner) }
    let(:member_user) { create(:user) }
    let(:member_musician) { create(:musician, user: member_user) }

    before do
      create(:involvement, band: band, musician: member_musician)
    end

    context "when not logged in" do
      it "redirects to login" do
        patch transfer_leadership_band_path(band), params: { musician_id: member_musician.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as band leader" do
      before { sign_in owner }

      it "transfers leadership to another member" do
        patch transfer_leadership_band_path(band), params: { musician_id: member_musician.id }
        expect(band.reload.user).to eq(member_user)
      end

      it "redirects to band edit page with success message" do
        patch transfer_leadership_band_path(band), params: { musician_id: member_musician.id }
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:notice]).to include("Leadership transferred")
      end

      it "fails when no musician is selected" do
        patch transfer_leadership_band_path(band), params: { musician_id: "" }
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("select a band member")
      end

      it "fails when musician is not a band member" do
        non_member = create(:musician)
        patch transfer_leadership_band_path(band), params: { musician_id: non_member.id }
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("not a member")
      end

      it "fails when trying to transfer to self" do
        owner_musician = owner.musician
        patch transfer_leadership_band_path(band), params: { musician_id: owner_musician.id }
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("already the band leader")
      end
    end

    context "when logged in as non-leader member" do
      before { sign_in member_user }

      it "does not allow transfer" do
        other_user = create(:user)
        other_musician = create(:musician, user: other_user)
        create(:involvement, band: band, musician: other_musician)

        patch transfer_leadership_band_path(band), params: { musician_id: other_musician.id }
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("Only the band leader")
      end
    end
  end

  describe "POST /bands" do
    context "when logged in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "sets the current user as the band owner" do
        post bands_path, params: { band: { name: "New Band", description: "A new band" } }
        expect(Band.last.user).to eq(user)
      end

      it "creates a chat for the new band" do
        post bands_path, params: { band: { name: "New Band", description: "A new band" } }
        expect(Band.last.chat).to be_present
      end
    end
  end

  describe "PATCH /bands/:id" do
    let(:owner) { create(:user) }
    let(:band) { create(:band, user: owner) }

    context "with genre updates" do
      before { sign_in owner }

      it "updates genres" do
        patch band_path(band), params: { band: { genre_list: ["Rock", "Jazz"] } }
        expect(band.reload.genre_list).to include("Rock", "Jazz")
      end

      it "updates description" do
        patch band_path(band), params: { band: { description: "New description" } }
        expect(band.reload.description).to eq("New description")
      end

      it "updates location" do
        patch band_path(band), params: { band: { location: "New York" } }
        expect(band.reload.location).to eq("New York")
      end
    end
  end
end
