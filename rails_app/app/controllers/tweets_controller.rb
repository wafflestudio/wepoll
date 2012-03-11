#coding:utf-8
class TweetsController < ApplicationController
  before_filter :authenticate_user!, :only => [:like]

  def get_tweet
    # TODO get former tweets
    screen_name = params[:screen_name]
    politician = Politician.where(:tweet_name => screen_name).first

#    politician = p
#    screen_name = p.tweet_name
    #get tweet if politician's tweet isn't protected and politician isn't nil
    unless (Twitter.user(screen_name).protected? || politician.nil?)
      need_more = false
      prev_last = politician.tweets.desc('created_at').first
      will_be_saved = []
      Twitter.user_timeline(screen_name,{:count => 60}).sort{|a,b| a.created_at <=> b.created_at}.each_with_index do |t,i|
        if (politician.tweets == [] || t.created_at > prev_last.created_at)
          tweet = Tweet.create(:created_at => t.created_at, :content => t.text, :status_id => t.id, :name => t.user.name, :screen_name => t.user.screen_name)
          will_be_saved << tweet
          if(i==0 && (politician.tweets != []))
            need_more = true
            last_status_id = tweet.status_id
          end
        end
      end
      if need_more
        all_tweets = get_tweet_more(prev_last.status_id, last_status_id)
        all_tweets.each do |t|
          tweet = Tweet.create(:created_at => t.created_at, :content => t.text, :status_id => t.id, :name => t.user.name, :screen_name => t.user.screen_name)
          will_be_saved << tweet
        end
      end
      politician.tweets.concat(will_be_saved)
    end
    redirect_to forum_path(politician)
  end

  def get_tweet_more(start_id, last_id) #트윗들 : Array
    got_tweets = Twitter.user_timeline(screen_name, {:count => 60, :since_id => start_id, :max_id => last_date})
    if got_tweets.nil?
      return []
    else
      if got_tweets.count == 60
        got_tweets << get_tweet_more(start_id, got_tweets_tweets.last.id)
      end
      return got_tweets
    end
  end

  def like
    @tweet = Tweet.find(params[:id])
    if @tweet.like(current_user)
      render :json => {:status => "ok", :count => @tweet.like_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end

  def replies
    @tweet = Tweet.find(params[:tweet_id])
    @replies = @tweet.tweet_replies.desc('created_at')
  end
end
