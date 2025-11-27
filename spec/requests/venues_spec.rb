require 'rails_helper'

RSpec.describe "Venues", type: :request do
  describe "GET /venues/:id" do
    let(:venue) { create(:venue) }

    it "returns a successful response" do
      get venue_path(venue)
      expect(response).to have_http_status(:success)
    end

    it "displays the venue details" do
      get venue_path(venue)
      expect(response.body).to include(venue.name)
    end
  end

  describe "GET /venues/new" do
    context "when not logged in" do
      it "redirects to login" do
        get new_venue_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as venue user" do
      let(:user) { create(:user, user_type: 'venue') }

      before { sign_in user }

      it "returns a successful response" do
        get new_venue_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /venues" do
    context "when not logged in" do
      it "redirects to login" do
        post venues_path, params: { venue: { name: "New Venue" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      let(:user) { create(:user, user_type: 'venue') }

      before { sign_in user }

      it "creates a new venue" do
        expect {
          post venues_path, params: { venue: { name: "New Venue", address: "123 Main St", city: "LA", capacity: 100 } }
        }.to change(Venue, :count).by(1)
      end

      it "associates the venue with the current user" do
        post venues_path, params: { venue: { name: "New Venue", address: "123 Main St", city: "LA", capacity: 100 } }
        expect(Venue.last.user).to eq(user)
      end
    end
  end

  describe "GET /venues/:id/edit" do
    let(:owner) { create(:user, user_type: 'venue') }
    let(:venue) { create(:venue, user: owner) }

    context "when not logged in" do
      it "redirects to login" do
        get edit_venue_path(venue)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as owner" do
      before { sign_in owner }

      it "returns a successful response" do
        get edit_venue_path(venue)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as non-owner" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with unauthorized message" do
        get edit_venue_path(venue)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /venues/:id" do
    let(:owner) { create(:user, user_type: 'venue') }
    let(:venue) { create(:venue, user: owner) }

    context "when logged in as owner" do
      before { sign_in owner }

      it "updates the venue" do
        patch venue_path(venue), params: { venue: { name: "Updated Venue" } }
        expect(venue.reload.name).to eq("Updated Venue")
      end
    end
  end

  describe "DELETE /venues/:id" do
    let(:owner) { create(:user, user_type: 'venue') }
    let!(:venue) { create(:venue, user: owner) }

    context "when logged in as owner" do
      before { sign_in owner }

      it "destroys the venue" do
        expect {
          delete venue_path(venue)
        }.to change(Venue, :count).by(-1)
      end
    end
  end
end
