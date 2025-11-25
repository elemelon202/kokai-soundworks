Rails.application.routes.draw do
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
  resources :musicians
  resources :bands do
    resources :involvements, only: [:new, :create]
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
end
