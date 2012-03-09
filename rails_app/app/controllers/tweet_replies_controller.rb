#coding:utf-8
class TweetRepliesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :recommend]

  def create
    if current_user.nil?
      render :json => {:status => "error", :message => "로그인 해 주십시오"}
      return
    end
    @re = TweetReply.new(params[:tweet_reply])
    @re.user = current_user
    @tweet = Tweet.find(params[:tweet_id])
    res = {}
    if @tweet.nil?
      render :json => {:status => "error", :message => "오류가 발생했습니다."}
      return
    else
      @tweet.tweet_replies << @re
      if @re.save
        res = {:status => "ok", :reply => @re, :message => "댓글달기가 완료되었습니다."}
        if(params[:tweet])
          if tweet_after_create
            res[:tweet] = "ok"
          else
            res[:status] = "error"
            res[:message] = "tweet을 게시하는데 오류가 발생했습니다."
          end
        end
        if(params[:facebook])
          if post_after_create
            res[:facebook] = "ok"
          else
            res[:status] = "error"
            res[:message] += "facebook에 포스팅하는데 오류가 발생했습니다."
          end
        end
        render :json => res
        return
      else
        render :json => {:status => "error", :message => "오류가 발생했습니다."}
        return
      end
    end
  end

  def tweet_after_create
    if current_user.twitter_token
      Twitter.configure do |config|
        config.consumer_key = TWITTER_CLIENT[:key]
        config.consumer_secret = TWITTER_CLIENT[:secret]
        config.oauth_token = current_user.twitter_token.access_token
        config.oauth_token_secret  = current_user.twitter_token.access_token_secret
      end

      Twitter.update(params[:tweet_reply][:content])
      true
    else
      false
    end
  end

  def post_after_create
    @facebook_cookies ||= Koala::Facebook::OAuth.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret]).get_user_info_from_cookie(cookies)
    unless @facebook_cookies.nil?
      @access_token = @facebook_cookies["access_token"]
      @graph = Koala::Facebook::GraphAPI.new(@access_token)
      @graph.put_object("me","feed",:message => params[:tweet_reply][:content])
      true
    else
      false
    end
  end

  def recommend
    @re = TweetReply.find(params[:tweet_reply_id])
    if @re.recommend(current_user)
      render :json => {:status => "ok", :count => @re.recommend_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end
  def report
    @re = TweetReply.find(params[:tweet_reply_id])
    if @re.report(current_user)
      render :json => {:status => "ok", :count => @re.report_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end
  
end
