Wepoll::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  namespace :me do
    match 'sns' => "sns#index"
    match '/' => 'dashboard#index'
  end
  match '/sns_verify/:user_id/:token_id/:key' => 'me/sns#verify_sns_link',
    :via => :get, :as => :sns_link_verify

  root :to => 'main#index'
end
