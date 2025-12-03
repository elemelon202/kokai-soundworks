Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  root to: "pages#home"

  # MAINSTAGE weekly contest (Musicians)
  get 'mainstage', to: 'mainstage#index', as: :mainstage
  post 'mainstage/vote', to: 'mainstage#vote', as: :mainstage_vote
  get 'mainstage/winners', to: 'mainstage#past_winners', as: :mainstage_winners

  # BAND MAINSTAGE weekly contest
  get 'band-mainstage', to: 'band_mainstage#index', as: :band_mainstage
  post 'band-mainstage/vote', to: 'band_mainstage#vote', as: :band_mainstage_vote
  get 'band-mainstage/winners', to: 'band_mainstage#past_winners', as: :band_mainstage_winners
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  resources :musician_shorts, only: [:index], path: 'discover', as: 'discover_shorts' do
    member do
      post :like
      delete :unlike
    end
    resources :short_comments, only: [:create, :destroy], path: 'comments'
  end
  resources :musicians do
    collection do
      get :search
    end
    member do
      delete :purge_attachment
    end
  #   GET    /musicians/:musician_id/shorts/new     -> new
  #   POST   /musicians/:musician_id/shorts         -> create
  #   GET    /musicians/:musician_id/shorts/:id/edit -> edit
  #   PATCH  /musicians/:musician_id/shorts/:id     -> update
  #   DELETE /musicians/:musician_id/shorts/:id     -> destroy
    resources :shorts, controller: "musician_shorts", only: [:new, :create,:edit, :update, :destroy] do
      collection do
        patch :reorder
    # collection routes don't require :id parameter
    # Generates: PATCH /musicians/:musician_id/shorts/reorder -> reorder
      end
    end
    collection do
      get :search # Generates: GET /musicians/search -> search
    end
    member do
      delete :purge_attachment # Generates: DELETE /musicians/:id/purge_attachment -> purge_attachment
      post :follow   # Generates: POST /musicians/:id/follow -> follow
      delete :unfollow # Generates: DELETE /musicians/:id/unfollow -> unfollow
      post :save_profile
      delete :unsave_profile
    end
    resources :endorsements, only: [:create, :destroy]
    resources :shoutouts, only: [:create, :destroy]
    resources :shorts, controller: "musician_shorts", only: [:new, :create, :edit, :update, :destroy] do
      collection do
        patch :reorder # Generates: PATCH /musicians/:musician_id/shorts/reorder -> reorder
      end
    end
  end

  resources :bands do
    resources :involvements, only: [:new, :create]
    resources :band_invitations, only: [:new, :create, :edit, :destroy]
    resources :spotify_tracks, only: [:create, :destroy]
    resources :band_events, only: [:create, :update, :destroy]
    resources :member_availabilities, only: [:create, :destroy]
    resources :kanban_tasks, only: [:index, :create, :update, :destroy], path: 'tasks'
    resources :band_gigs, only: [:create, :destroy], path: 'gigs'
    member do
      patch :transfer_leadership
      delete :purge_attachment
      post :follow
      delete :unfollow
      post :save_profile
      delete :unsave_profile
    end
  end

  #These routes can't be nested because they need to be accessed via token only. The routes band_invitations#new and #create are nested because they are used when sending an invite.
  get 'accept_invitation/:token', to: 'band_invitations#accept', as: 'accept_band_invitation'
  get 'decline_invitation/:token', to: 'band_invitations#decline', as: 'decline_band_invitation'
# config/routes.rb
  resources :band_invitations, only: [] do
    collection do
      get :sent
    end
    member do
      patch :accept
      patch :decline
    end
  end
  resources :involvements, only: [:edit, :update, :destroy]
  # resources :kanban_tasks do
  #   collection do
  #     post :sort
  #   end
  # end
  resources :venues do
    resources :gigs, only: [:new, :create, :index]
    member do
      delete :purge_photo
    end
  end
  get 'discover-gigs', to: 'gigs#discover', as: :discover_gigs
  get 'swipe-gigs', to: 'gigs#swipe', as: :swipe_gigs
  resources :gigs, only: [:show, :index, :edit, :update] do
    resources :bookings, only: [:new, :create, :destroy]
    resources :gig_applications, only: [:create]
    member do
      post :check_in
      post :rsvp
    end
  end
  resources :bookings, only: [:edit, :update]
  resources :chats do
    resources :messages, only: [:create]
  end
  resources :direct_messages, only: [:index, :show, :destroy] do
    collection do
      post :create_or_show
    end
  end

  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end
   resources :chats, only: [:show] do
    resources :messages, only: [:create, :destroy]
  end

  resources :friendships, only: [:index, :create, :destroy] do
    member do
      patch :accept
      patch :decline
    end
  end

  # Saved musicians and bands
  get 'saved', to: 'saved#index', as: :saved

  resources :posts, only: [:index, :create, :destroy], path: 'feed' do
    member do
      post :repost
      post :like
      delete :unlike
    end
    resources :post_comments, only: [:create, :destroy], path: 'comments'
  end

  # Challenges (Phase 4)
  resources :challenges do
    member do
      get :respond
      post :submit_response
      post :start_voting
      post :close
      post :pick_winner
    end
    collection do
      post :vote
      delete :unvote
    end
  end
  post 'challenges/vote/:response_id', to: 'challenges#vote', as: :challenge_vote
  delete 'challenges/unvote/:response_id', to: 'challenges#unvote', as: :challenge_unvote

  resources :fans, only: [:show, :edit, :update] do
    member do
      get :gigs
      get :following
      get :saved
      get :friends
    end
  end

  resources :gig_applications, only: [:index] do
    member do
      patch :approve
      patch :reject
    end
  end
end
