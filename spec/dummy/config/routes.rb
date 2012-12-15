Dummy::Application.routes.draw do
  resources :entities do
    resources :things

    post :penetrate, :on => :member
  end

  resources :fluffies

  resources :posts do
    resources :comments, :controller => :post_comments
  end
end
