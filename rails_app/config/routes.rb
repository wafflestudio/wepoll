Wepoll::Application.routes.draw do
  resources :timeline_entries do
    match '/recommend' => 'timeline_entries#recommend', :as => :recommend
  end
  resources :bills
  resources :link_replies

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
    match '/auth_completed' => 'users/registrations#after_auth', :as => :after_auth
  end

  match 'users/auth/twitter/callback' => 'users/omniauth_callbacks#twitter'


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
    post 'tweet_replies' => 'tweet_replies#create', :as => :tweet_replies
    get 'tweet_replies' => 'tweets#replies', :as => :tweet_replies
  end
  resources :tweet_replies do
    match '/recommend' => 'tweet_replies#recommend', :as => :recommend
    match '/report' => 'tweet_replies#report', :as => :report
  end

  match '/fb_post_callback' => 'tweet_replies#fb_post_callback', :as => :fb_post_callback

  match 'district/:name/:p1_id/:p2_id' => 'district#show' ,:constraints => {:p1_id => /[a-z0-9]+/, :p2_id => /[a-z0-9]+/}, :as => :district_vs_politicians
  match 'district/:politician_id' => 'district#show' ,:constraints => {:politician_id => /[a-z0-9]+/}, :as => :district_politician
  match 'district/:name' => "district#show", :as => :district_name

  resources :politicians do
    get 'initiate_bills', :on => :member, :as => :init_bills_by
    get 'bill_activities', :on => :collection, :as => :bill_activities_of
    get 'profile', :on => :collection, :as => :profiles_of
    get 'promises', :on => :collection, :as => :promises_of
  end

  match "/search" => "main#search"

  root :to => 'main#index'


  #for test
  match 'main/fb_test' => 'main#facebook_test', :as => :fb_test
  match 'main/fb_test_callback' => 'main#facebook_test_callback', :as => :fb_test_callback

  match 'main/tw_test' => 'main#twitter_test', :as => :tw_test
  match 'api/article_parse' => 'api#article_parsing'
  match 'api/youtube_parse' => 'api#youtube_parsing'

end

