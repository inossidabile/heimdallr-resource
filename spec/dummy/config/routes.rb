Dummy::Application.routes.draw do
  resources :entities do
    resources :things

    post :penetrate, :on => :member
  end

  resources :fluffies
end
