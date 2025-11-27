require 'rails_helper'

RSpec.describe "Musicians", type: :request do
  describe "GET /musicians" do
    let!(:musician1) { create(:musician, name: "John Doe", instrument: "Guitar") }
    let!(:musician2) { create(:musician, name: "Jane Smith", instrument: "Bass") }

    it "returns a successful response" do
      get musicians_path
      expect(response).to have_http_status(:success)
    end

    it "displays all musicians" do
      get musicians_path
      expect(response.body).to include(musician1.name)
      expect(response.body).to include(musician2.name)
    end

    context "with search query" do
      it "filters musicians by search term" do
        get musicians_path, params: { query: "John" }
        expect(response.body).to include("John Doe")
      end
    end

    context "with instrument filter" do
      it "filters musicians by instrument" do
        get musicians_path, params: { instrument: "Guitar" }
        expect(response.body).to include("John Doe")
      end
    end

    context "with location filter" do
      let!(:musician_nyc) { create(:musician, location: "New York") }
      let!(:musician_la) { create(:musician, location: "Los Angeles") }

      it "filters musicians by location" do
        get musicians_path, params: { location: "New York" }
        expect(response.body).to include(musician_nyc.name)
      end
    end
  end

  describe "GET /musicians/:id" do
    let(:musician) { create(:musician) }

    it "returns a successful response" do
      get musician_path(musician)
      expect(response).to have_http_status(:success)
    end

    it "displays the musician details" do
      get musician_path(musician)
      expect(response.body).to include(musician.name)
    end
  end

  describe "GET /musicians/new" do
    context "when not logged in" do
      it "redirects to login" do
        get new_musician_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "returns a successful response" do
        get new_musician_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /musicians" do
    context "when not logged in" do
      it "redirects to login" do
        post musicians_path, params: { musician: { name: "New Musician" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "creates a new musician" do
        expect {
          post musicians_path, params: { musician: { name: "New Musician", instrument: "Drums" } }
        }.to change(Musician, :count).by(1)
      end

      it "associates the musician with the current user" do
        post musicians_path, params: { musician: { name: "New Musician", instrument: "Drums" } }
        expect(Musician.last.user).to eq(user)
      end
    end
  end

  describe "GET /musicians/:id/edit" do
    let(:user) { create(:user) }
    let(:musician) { create(:musician, user: user) }

    context "when not logged in" do
      it "redirects to login" do
        get edit_musician_path(musician)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get edit_musician_path(musician)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as another user" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with unauthorized message" do
        get edit_musician_path(musician)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /musicians/:id" do
    let(:user) { create(:user) }
    let(:musician) { create(:musician, user: user) }

    context "when logged in as owner" do
      before { sign_in user }

      it "updates the musician" do
        patch musician_path(musician), params: { musician: { name: "Updated Name" } }
        expect(musician.reload.name).to eq("Updated Name")
      end
    end
  end

  describe "DELETE /musicians/:id" do
    let(:user) { create(:user) }
    let!(:musician) { create(:musician, user: user) }

    context "when logged in as owner" do
      before { sign_in user }

      it "destroys the musician" do
        expect {
          delete musician_path(musician)
        }.to change(Musician, :count).by(-1)
      end
    end
  end
end
