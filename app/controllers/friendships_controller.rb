class FriendshipsController < ApplicationController
    before_action :authenticate_user!

     def index
    skip_authorization
    skip_policy_scope
    @friends = current_user.friends
    @pending_requests = current_user.pending_friend_requests.includes(:requester)
    @sent_requests = current_user.sent_friend_requests.pending.includes(:addressee)
  end

    def create
      @addressee = User.find(params[:addressee_id])
      skip_authorization

      # Check if request already exists in either direction
      existing = Friendship.find_by(requester: current_user, addressee: @addressee) ||
                 Friendship.find_by(requester: @addressee, addressee: current_user)

      if existing
        redirect_back fallback_location: root_path, alert: "Friend request already exists."
        return
      end

      @friendship = Friendship.new(requester: current_user, addressee: @addressee, status: 'pending')

      if @friendship.save
        Notification.create_for_friend_request(@friendship)
        redirect_back fallback_location: root_path, notice: "Friend request sent!"
      else
        redirect_back fallback_location: root_path, alert: @friendship.errors.full_messages.join(", ")
      end
    end

    def accept
      @friendship = Friendship.find(params[:id])
      skip_authorization

      if @friendship.addressee == current_user
        @friendship.update(status: 'accepted')
        Notification.create_for_friend_request_accepted(@friendship)
        redirect_back fallback_location: friendships_path, notice: "Friend request accepted!"
      else
        redirect_back fallback_location: friendships_path, alert: "You can't accept this request."
      end
    end

    def decline
      @friendship = Friendship.find(params[:id])
      skip_authorization

      if @friendship.addressee == current_user
        @friendship.update(status: 'declined')
        redirect_back fallback_location: friendships_path, notice: "Friend request declined."
      else
        redirect_back fallback_location: friendships_path, alert: "You can't decline this request."
      end
    end

    def destroy
      @friendship = Friendship.find(params[:id])
      skip_authorization

      if @friendship.requester == current_user || @friendship.addressee == current_user
        @friendship.destroy
        redirect_back fallback_location: friendships_path, notice: "Friend removed."
      else
        redirect_back fallback_location: friendships_path, alert: "You can't remove this friendship."
      end
    end
end
