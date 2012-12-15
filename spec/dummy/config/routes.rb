Dummy::Application.routes.draw do
  resources :posts do
    resources :comments, :controller => :post_comments
    post :hide, :on => :member
  end
end
