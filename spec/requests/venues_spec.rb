require 'rails_helper'

RSpec.describe "Venues", type: :request do
  describe "GET /venues" do
    let!(:venue1) { create(:venue) }
    let!(:venue2) { create(:venue) }

    it "returns a successful response" do
      get venues_path
      expect(response).to have_http_status(:success)
    end

    it "displays all venues" do
      get venues_path
      expect(response.body).to include(venue1.name)
      expect(response.body).to include(venue2.name)
    end
  end

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

    it "displays the venue address" do
      get venue_path(venue)
      expect(response.body).to include(venue.address)
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

      it "redirects to venues index" do
        delete venue_path(venue)
        expect(response).to redirect_to(venues_path)
      end
    end

    context "when logged in as non-owner" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not destroy the venue" do
        expect {
          delete venue_path(venue)
        }.not_to change(Venue, :count)
      end

      it "redirects with unauthorized message" do
        delete venue_path(venue)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /venues/:id" do
    let(:owner) { create(:user, user_type: 'venue') }
    let(:venue) { create(:venue, user: owner) }

    context "when logged in as non-owner" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "does not update the venue" do
        original_name = venue.name
        patch venue_path(venue), params: { venue: { name: "Unauthorized Update" } }
        expect(venue.reload.name).to eq(original_name)
      end

      it "redirects with unauthorized message" do
        patch venue_path(venue), params: { venue: { name: "Unauthorized Update" } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when updating venue details" do
      before { sign_in owner }

      it "updates the address" do
        patch venue_path(venue), params: { venue: { address: "456 New Street" } }
        expect(venue.reload.address).to eq("456 New Street")
      end

      it "updates the capacity" do
        patch venue_path(venue), params: { venue: { capacity: 1000 } }
        expect(venue.reload.capacity).to eq(1000)
      end

      it "redirects to venue show page after update" do
        patch venue_path(venue), params: { venue: { name: "Updated Venue" } }
        expect(response).to redirect_to(venue_path(venue))
      end
    end
  end

  describe "POST /venues" do
    context "when logged in" do
      let(:user) { create(:user, user_type: 'venue') }

      before { sign_in user }

      it "redirects to the new venue after creation" do
        post venues_path, params: { venue: { name: "New Venue", address: "123 Main St", city: "LA", capacity: 100 } }
        expect(response).to redirect_to(venue_path(Venue.last))
      end

      it "creates venue with all attributes" do
        post venues_path, params: { venue: { name: "New Venue", address: "123 Main St", city: "LA", capacity: 200, description: "A great venue" } }
        venue = Venue.last
        expect(venue.name).to eq("New Venue")
        expect(venue.address).to eq("123 Main St")
        expect(venue.city).to eq("LA")
        expect(venue.capacity).to eq(200)
        expect(venue.description).to eq("A great venue")
      end
    end
  end
end
