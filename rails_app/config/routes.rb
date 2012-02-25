Wepoll::Application.routes.draw do
  resources :timeline_entries

  namespace :admin do
    match '/' => 'admin#index'
    match 'login' => 'auth#login'
    match 'logout' => 'auth#logout'
    match 'authorize' => 'auth#authorize'
    match 'new' => 'admin#new_admin', :via => :get
    match 'create' => 'admin#create_admin', :via => :post
    resources 'politicians' do
      get 'search', :as => 'search', :on => :collection
      post 'upload_photo', :as => 'upload_photo', :on => :collection
    end
    resources 'bills' do
      get 'search', :as => 'search', :on => :collection
    end

    resources 'timeline_entries'
    resources 'users'
  end

  devise_for :users, :controllers => {
    :omniauth_callbacks => "users/omniauth_callbacks",
    :registrations => "users/registrations",
    :sessions => "users/sessions"} do
    match 'users/sign_up/link_sns/:id' => 'users/registrations#link_sns', :via => :get, :as => 'new_user_link_sns'
  end

  namespace :me do
    match 'sns/' => "sns#index"
    match 'sns/link/:provider' => "sns#link", :as => :sns_link
    match 'sns/mail_fail' => 'sns#mail_resend', :as => :sns_mail_resend

    match '/' => 'dashboard#index', :as => "dashboard"
  end
  match '/sns_verify/:user_id/:token_id/:key' => 'me/sns#verify_sns_link',
    :via => :get, :as => :sns_link_verify

  match '/forum/:politician_id' => 'main#forum' , :as => :forum
  match '/get_tweet/:screen_name' => 'tweets#get_tweet', :as => :get_tweet

  resources :tweets do
    match '/recommend' => 'tweets#recommend', :as => :recommend
    match '/opposite' => 'tweets#opposite', :as => :opposite
    post 'tweet_replies' => 'tweet_replies#create', :as => :tweet_replies
  end
  resources :tweet_replies do
    match '/recommend' => 'tweet_replies#recommend', :as => :recommend
    match '/opposite' => 'tweet_replies#opposite', :as => :opposite
    match '/report' => 'tweet_replies#report', :as => :report
  end


  match "/search" => "main#search"
  root :to => 'main#index'


  #for test
  match 'main/fb_test' => 'main#facebook_test', :as => :fb_test
  match 'main/fb_test_callback' => 'main#facebook_test_callback', :as => :fb_test_callback
end
