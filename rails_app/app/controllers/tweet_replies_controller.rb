#coding:utf-8
class TweetRepliesController < ApplicationController
  before_filter :user_signed_in?, :only => [:create, :tweet_after_create]

  def create
    @re = TweetReply.new(:content => params[:content])
    @re.user = current_user
    @tweet = Tweet.find(params[:tweet_id])
    if @tweet.nil?
      render :json => {:status => "error", :message => "오류가 발생했습니다."}
    else
      @tweet.tweet_replies << @re
      @re.save
      if(params[:tweet])
        if tweet_after_create
          render :json => {:status => "ok", :reply => @re }
        else
          render :json => {:status => "error", :message => "오류가 발생했습니다."}
        end
      end
    end
  end

  def tweet_after_create
    if current_user && current_user.twitter_token
      Twitter.configure do |config|
        config.consumer_key = TWITTER_CLIENT[:key]
        config.consumer_secret = TWITTER_CLIENT[:secret]
        config.oauth_token = current_user.twitter_token.access_token
        config.oauth_token_secret  = current_user.twitter_token.access_token_secret
      end
      Twitter.update(params[:content])
      true
    else
      false
    end
  end

  def post_after_create
    if current_user && current_user.facebook_token
    end
  end
    

  def recommend
    @re = TweetReply.find(params[:tweet_reply_id])
    if @re.recommend(current_user)
      render :json => {:status => "ok", :count => @re.recommend_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def report
    @re = TweetReply.find(params[:tweet_reply_id])
    if @re.report(current_user)
      render :json => {:status => "ok", :count => @re.report_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  
end
