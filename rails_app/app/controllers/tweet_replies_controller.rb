#coding:utf-8
class TweetRepliesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :like]

  def create
    if current_user.nil?
      render :json => {:status => "error", :message => "로그인 해 주십시오"}
      return
    end
    @re = TweetReply.new(params[:tweet_reply])
    @re.user = current_user
    @tweet = Tweet.find(params[:tweet_id])
    @error = 0
    @message = ""
    if @tweet.nil?
      @error = 1
      @message = "해당 트윗이 없습니다."
      return
    else
      @tweet.tweet_replies << @re
      if @re.save
        @replies = @tweet.tweet_replies.desc('created_at')
        if(params[:tweet])
          unless tweet_after_create
            @error = 1
            @message += "tweet을 게시하는데 오류가 발생했습니다."
          end
        end
        if(params[:facebook])
          unless post_after_create
            @error = 1
            @message += "facebook에 포스팅하는데 오류가 발생했습니다."
          end
        end
        return
      else
        @error = 1
        @message = "저장하는데 오류가 발생했습니다."
        return
      end
    end
  end


  def like
    @re = TweetReply.find(params[:id])
    if @re.like(current_user)
      render :json => {:status => "ok", :count => @re.like_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end
  def blame
    @re = TweetReply.find(params[:id])
    if @re.blame(current_user)
      render :json => {:status => "ok", :count => @re.blame_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end
  
  protected
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
      @graph.put_object("me","feed",:message => params[:tweet_reply][:content], :link => params[:link], :picture => "http://choco.wafflestudio.net:3082/btn_wepoll.png" )
      true
    else
      false
    end
  end
end
