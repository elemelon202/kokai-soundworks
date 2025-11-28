require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:band) { create(:band) }

  describe "GET /notifications" do
    context "when not logged in" do
      it "redirects to login" do
        get notifications_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "returns a successful response" do
        get notifications_path
        expect(response).to have_http_status(:success)
      end

      it "returns JSON when requested" do
        get notifications_path, as: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "includes notifications in the response" do
        Notification.create!(
          user: user,
          actor: create(:user),
          notifiable: band,
          notification_type: Notification::TYPES[:band_member_joined],
          message: "Test notification",
          read: false
        )
        get notifications_path
        expect(response.body).to include("Test notification")
      end
    end
  end

  describe "PATCH /notifications/:id/mark_as_read" do
    let!(:notification) do
      Notification.create!(
        user: user,
        actor: create(:user),
        notifiable: band,
        notification_type: Notification::TYPES[:band_member_joined],
        message: "Test notification",
        read: false
      )
    end

    context "when not logged in" do
      it "redirects to login" do
        patch mark_as_read_notification_path(notification)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "marks the notification as read" do
        patch mark_as_read_notification_path(notification)
        expect(notification.reload.read).to be true
      end

      it "returns JSON when requested" do
        patch mark_as_read_notification_path(notification), as: :json
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end
    end
  end

  describe "PATCH /notifications/mark_all_as_read" do
    let!(:notification1) do
      Notification.create!(
        user: user,
        actor: create(:user),
        notifiable: band,
        notification_type: Notification::TYPES[:band_member_joined],
        message: "Test notification 1",
        read: false
      )
    end
    let!(:notification2) do
      Notification.create!(
        user: user,
        actor: create(:user),
        notifiable: band,
        notification_type: Notification::TYPES[:band_member_joined],
        message: "Test notification 2",
        read: false
      )
    end

    context "when not logged in" do
      it "redirects to login" do
        patch mark_all_as_read_notifications_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "marks all notifications as read" do
        patch mark_all_as_read_notifications_path
        expect(notification1.reload.read).to be true
        expect(notification2.reload.read).to be true
      end

      it "redirects to notifications index" do
        patch mark_all_as_read_notifications_path
        expect(response).to redirect_to(notifications_path)
      end

      it "returns JSON when requested" do
        patch mark_all_as_read_notifications_path, as: :json
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["unread_count"]).to eq(0)
      end
    end
  end
end
