Rails.application.routes.draw do
  get 'users/show'

  devise_for :users, controllers: { registrations: 'registrations' }, skip: [:registrations]
  devise_scope :user do
    get 'users/sign_up', to: 'registrations#new', as: :new_user_registration
    post 'users', to: 'registrations#create', as: :user_registration
    get 'users/sign_out', to: 'devise/sessions#destroy'
  end

  namespace :admin do
    resources :users, only: [:new, :create, :index]
    resources :faculties, only: [:new, :create, :destroy, :index]
  end

  resources :workspace, only: [:new, :create]
  post 'delete_folder', to: 'workspace#delete_folder'

  resources :documents do
    member do
      get :download
      patch :update
    end
    collection do
      get :index
      get :search
    end
  end

  resources :faculties, only: [:show]

  resources :users, only: [:index, :show, :edit, :update, :destroy]
  
  root "knowledge_app#index"
end
