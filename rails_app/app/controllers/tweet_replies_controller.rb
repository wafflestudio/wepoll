#coding:utf-8
class TweetRepliesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :like]

  def index
    @tweet = Tweet.find(params[:tweet_id])
    @replies = @tweet.tweet_replies.desc('created_at')
  end

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

  def destroy
    @reply = TweetReply.find(params[:id])
    @success = false
    @id = params[:id]
    if @reply.user == current_user
      if @reply.destroy
        @success = true
      else
        @success = false
      end
    else
      @success = false
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
      render :json => {:status => "error", :message => "이미 신고하셨습니다."}
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

      begin
        Twitter.update(params[:tweet_reply][:content])
        true
      rescue Twitter::Error => e
        Rails.logger.info "Tiwtter tweet error"
        puts "Tiwtter tweet error"
        Rails.logger.info e.message
        puts e.message
        false
      end
    else
      Rails.logger.info "twitter token doesn't exist"
      puts "twitter token doesn't exist"
      false
    end
  end

  def post_after_create
    @facebook_cookies ||= Koala::Facebook::OAuth.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret]).get_user_info_from_cookie(cookies)
    unless @facebook_cookies.nil?
      begin
        @access_token = @facebook_cookies["access_token"]
        @graph = Koala::Facebook::GraphAPI.new(@access_token)
        Rails.logger.info @graph.put_object("me","feed",:message => params[:tweet_reply][:content], :link => params[:link], :picture => "http://wepoll.or.kr/btn_wepoll.png" )
        true
      rescue StandardError => e
        Rails.logger.info e.message
        puts e.message
      end
    else
      Rails.logger.info "facebook cookie doesn't exist"
      puts "facebook cookie doesn't exist"
      false
    end
  end
end
