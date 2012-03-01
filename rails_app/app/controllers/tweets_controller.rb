#coding:utf-8
class TweetsController < ApplicationController

  def get_tweet
    # TODO get former tweets

    screen_name = params[:screen_name]
    politician = Politician.where(:tweet_name => screen_name).first

    #get tweet if politician's tweet isn't protected and politician isn't nil
    unless (Twitter.user(screen_name).protected? || politician.nil?)
      # sort tweets by created_at(date time)
      Twitter.user_timeline(screen_name).sort{|a,b| a.created_at <=> b.created_at}.each do |t|
        #save tweet if tweet is not saved in former times
        if (politician.tweets == [] || t.created_at > politician.tweets.desc('created_at').first.created_at)
          tweet = Tweet.create(:created_at => t.created_at, :content => t.text)
          politician.tweets << tweet
        end
      end
    end
    redirect_to forum_path(politician)

  end

  def recommend
    @tweet = Tweet.find(params[:tweet_id])
    ip = request.remote_ip
    if @tweet.recommend(ip)
      render :json => {:status => "ok", :count => @tweet.recommend_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def opposite
    @tweet = Tweet.find(params[:tweet_id])
    ip = request.remote_ip
    if @tweet.opposite(ip)
      render :json => {:status => "ok", :count => @tweet.opposite_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
end
