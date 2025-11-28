require 'rails_helper'

RSpec.describe "Involvements", type: :request do
  let(:band_owner) { create(:user) }
  let(:band) { create(:band, user: band_owner) }
  let(:member_user) { create(:user) }
  let(:member_musician) { create(:musician, user: member_user) }
  let!(:involvement) { create(:involvement, band: band, musician: member_musician) }

  describe "DELETE /involvements/:id" do
    context "when not logged in" do
      it "redirects to login" do
        delete involvement_path(involvement)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as band leader" do
      before { sign_in band_owner }

      it "can remove a band member" do
        expect {
          delete involvement_path(involvement)
        }.to change(Involvement, :count).by(-1)
      end

      it "redirects to band edit page with success message" do
        delete involvement_path(involvement)
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:notice]).to include("has been removed")
      end

      it "cannot leave the band as the leader" do
        # First get the owner's involvement (created via callback)
        owner_involvement = band.involvements.find_by(musician: band_owner.musician)
        delete involvement_path(owner_involvement)
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("cannot leave the band")
      end
    end

    context "when logged in as band member (non-owner)" do
      before { sign_in member_user }

      it "can leave the band" do
        expect {
          delete involvement_path(involvement)
        }.to change(Involvement, :count).by(-1)
      end

      it "redirects to bands index with success message" do
        delete involvement_path(involvement)
        expect(response).to redirect_to(bands_path)
        expect(flash[:notice]).to include("You have left")
      end

      it "cannot remove other members" do
        other_user = create(:user)
        other_musician = create(:musician, user: other_user)
        other_involvement = create(:involvement, band: band, musician: other_musician)

        delete involvement_path(other_involvement)
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("not authorized")
      end
    end

    context "when logged in as non-member" do
      let(:random_user) { create(:user) }

      before { sign_in random_user }

      it "cannot remove members" do
        delete involvement_path(involvement)
        expect(response).to redirect_to(edit_band_path(band))
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end
end
