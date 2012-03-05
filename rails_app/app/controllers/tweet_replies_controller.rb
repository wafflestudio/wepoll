#coding:utf-8
class TweetRepliesController < ApplicationController
  #before_filter :authenticate_user!, :only => [:create]

  def create
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
        res = {:status => "ok", :reply => @re}
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
            res[:message] = "facebook에 포스팅하는데 오류가 발생했습니다."
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
      Twitter.update(params[:content])
      true
    else
      false
    end
  end

  def post_after_create
    true
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
