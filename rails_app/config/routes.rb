Wepoll::Application.routes.draw do
  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'}

  root :to => 'main#index'
  match '/mypage' => "users#mypage", :as => :mypage
end
