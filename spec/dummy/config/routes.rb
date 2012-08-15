Dummy::Application.routes.draw do
  resources :entities do
    member do
      post :penetrate
    end
  end
  resources :fluffies
end
