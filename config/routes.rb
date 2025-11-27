Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  root to: "pages#home"
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  resources :musicians do
    collection do
      get :search
    end
    member do
      delete :purge_attachment
    end
  end
  resources :bands do
    resources :involvements, only: [:new, :create]
    resources :band_invitations, only: [:new, :create, :edit, :destroy]
    member do
      patch :transfer_leadership
      delete :purge_attachment
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
  end
  resources :gigs, only: [:show, :index] do
    resources :bookings, only: [:new, :create, :destroy]
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
end
