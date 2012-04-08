Dummy::Application.routes.draw do
  resources :entity do
    member do
      post :penetrate
    end
  end
  resources :fluffies
end