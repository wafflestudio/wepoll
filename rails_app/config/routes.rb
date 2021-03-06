Wepoll::Application.routes.draw do
  resources :timeline_entries do
    get 'blame', :on => :member
    get 'like', :on => :member
    get 'entry', :on => :member
  end

  resources :messages do 
		match '/list' => 'messages#list', :as => "list"
    post 'message_replies' => 'message_replies#create', :as => :replies
    get 'message_replies' => 'message_replies#index', :as => :replies
    get 'blame', :on => :member
    get 'like', :on => :member
  end

  resources :message_replies, :only => [:destroy]
  match "link_counts/:id" => "politicians#link_counts", :as => :link_counts_of_politician, :constraints => {:id => /[a-z0-9]+/}
  match "link_counts/:district" => "politicians#link_counts", :as => :link_counts_of_politician
  match 'timeline/:timeline_entry_id' => 'district#show_timeline_entry', :via => :get, :as => :display_timeline_entry
#  match "timeline_entries/list/:id" => "timeline_entries#list", :as => "timeline_entries_list"

  resources :bills
  resources :link_replies do
    match "/list" => "link_replies#list", :as => "list"
    get 'blame', :on => :member
    get 'like', :on => :member
  end
  resources :notices

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
      get 'crawl_init_bills', :as => 'crawl_initiate_bill', :on => :member
    end
    resources 'bills' do
      get 'search', :as => 'search', :on => :collection
    end

    resources 'timeline_entries'
    resources 'users' do
      get 'suspend', :as => 'suspend', :on => :member
      post 'suspend_confirm', :as => 'suspend_confirm', :on => :member
      post 'suspend_cancel', :as => 'suspend_cancel', :on => :member
    end

    resources 'notices'
    resources 'link_replies'
    resources 'tweet_replies'
    resources 'tweets'
    resources 'pledges' do
      get 'search', :as => 'search', :on => :collection
    end
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

  get 'forum/:tweet_name' => 'tweets#forum' , :as => :forum
  match '/get_tweet/:screen_name' => 'tweets#get_tweet', :as => :get_tweet

  resources :tweets do
    get 'like', :on => :member
    post 'tweet_replies' => 'tweet_replies#create', :as => :tweet_replies
    get 'tweet_replies' => 'tweet_replies#index', :as => :tweet_replies
  end
  resources :tweet_replies do
    get 'blame', :on => :member
    get 'like', :on => :member
    delete 'destroy', :on => :member
  end

  resources :pledges do
    get 'like', :on => :member, :as => :like
    get 'dislike', :on => :member, :as => :dislike
  end

  match '/fb_post_callback' => 'tweet_replies#fb_post_callback', :as => :fb_post_callback

  match 'district/:name/:p1_id/:p2_id' => 'district#show' ,:constraints => {:p1_id => /[a-z0-9]+/, :p2_id => /[a-z0-9]+/}, :as => :district_vs_politicians
  match 'district/:politician_id' => 'district#show' ,:constraints => {:politician_id => /[a-z0-9]+/}, :as => :district_politician
  match 'district/:name' => "district#show", :as => :district_name

  resources :politicians do
    get 'initiate_bills', :on => :member, :as => :init_bills_by
    get 'initiate_bills_summary',:on => :member, :as => :init_bills_summary_of
    get 'top_joint_initiate_bills',:on => :member, :as => :top_joint_initiate_bills_of
    get 'bill_activities', :on => :collection, :as => :bill_activities_of

    get 'popular_links', :on => :member, :as => :popular_links_of
    get 'recent_links', :on => :member, :as => :recent_links_of

    get 'popular_links_tab', :on => :collection, :as => :popular_links_tab_of
    get 'recent_links_tab', :on => :collection, :as => :recent_links_tab_of
    get 'votes_for_issues_tab', :on => :collection, :as => :votes_for_issues_tab_of

    get 'profile', :on => :collection, :as => :profiles_of
    get 'pledges', :on => :collection, :as => :pledges_of
    get 'messages_tab', :on => :collection, :as => :messages_tab_of

    get 'messages', :on => :collection, :as => :messages_of
  end

  match "/search" => "main#search"
match '/provision' => 'main#provision'
match '/privacy' => 'main#privacy'

  root :to => 'main#index'


  #for test
  match 'main/fb_test' => 'main#facebook_test', :as => :fb_test
  match 'main/fb_test_callback' => 'main#facebook_test_callback', :as => :fb_test_callback

  match 'main/tw_test' => 'main#twitter_test', :as => :tw_test
  match 'api/article_parse' => 'api#article_parsing'
  match 'api/youtube_parse' => 'api#youtube_parsing'
end

