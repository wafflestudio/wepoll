Wepoll::Application.routes.draw do
  devise_for :users, :controllers => {
    :omniauth_callbacks => "users/omniauth_callbacks",
    :registrations => "users/registrations",
    :sessions => "users/sessions"} do
    match 'users/sign_up/link_sns/:id' => 'users/registrations#link_sns', :via => :get, :as => 'new_user_link_sns'
  end

  namespace :me do
    match 'sns' => "sns#index"
    match 'sns/link/:provider' => "sns#link", :as => :sns_link
    match '/' => 'dashboard#index', :as => "dashboard"
  end
  match '/sns_verify/:user_id/:token_id/:key' => 'me/sns#verify_sns_link',
    :via => :get, :as => :sns_link_verify

  match '/forum/:politician_id' => 'main#forum' , :as => :forum
  root :to => 'main#index'
end
