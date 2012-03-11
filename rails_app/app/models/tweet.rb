class Tweet
  include Mongoid::Document

  field :status_id
  field :name
  field :screen_name
  field :content, type: String
  field :created_at, type: DateTime

  field :like_count, type: Integer, default: 0       # 추천
  field :today_like_count, type: Integer, default: 0 # 오늘의 추천


  has_many :tweet_replies
  belongs_to :politician
  has_and_belongs_to_many :like_users, :class_name => "User", :inverse_of => :like_tweets


  def like(user)
    if self.like_users.include? user
      false
    else
      self.like_count = self.like_count+1
      self.today_like_count = self.today_like_count+1
      self.like_users << user
      self.save
    end
  end

  def self.get_tweet
    # TODO get former tweets
#    screen_name = params[:screen_name]
#    politician = Politician.where(:tweet_name => screen_name).first
    #

    Twitter.configure do |config|
      config.consumer_key = TWITTER_CLIENT[:key]
      config.consumer_secret = TWITTER_CLIENT[:secret]
      config.oauth_token = TWITTER_ACCOUNT[:key]
      config.oauth_token_secret  = TWITTER_ACCOUNT[:secret]
    end

    Politician.all.each do |p|
      politician = p
      screen_name = politician.tweet_name
      #get tweet if politician's tweet isn't protected and politician isn't nil
      unless (screen_name.nil? || Twitter.user(screen_name).protected?)
        puts "start getting #{politician.name}'s tweet"
        Rails.logger.info "start getting #{politician.name}'s tweet"
        need_more = false
        prev_last = politician.tweets.desc('created_at').first
        will_be_saved = []
        begin
          Twitter.user_timeline(screen_name,{:count => 200}).sort{|a,b| a.created_at <=> b.created_at}.each_with_index do |t,i|
            if (politician.tweets == [] || t.created_at > prev_last.created_at)
              tweet = Tweet.create(:created_at => t.created_at, :content => t.text, :status_id => t.id, :name => t.user.name, :screen_name => t.user.screen_name)
              will_be_saved << tweet
              if(i==0 && (politician.tweets != []))
                puts "#{politician.name} need more tweet"
                Rails.logger.info "#{politician.name} need more tweet"
                need_more = true
                last_status_id = tweet.status_id
              end
            end
          end
        rescue Exception => e
          puts e
          Rails.logger.info e
        end
        if need_more
          puts "get more tweet for #{politician.name} "
          Rails.logger.info "get more tweet for #{politician.name} "
          all_tweets = get_tweet_more(prev_last.status_id, last_status_id)
          all_tweets.each do |t|
            tweet = Tweet.create(:created_at => t.created_at, :content => t.text, :status_id => t.id, :name => t.user.name, :screen_name => t.user.screen_name)
            will_be_saved << tweet
          end
        end
        puts "put tweets into #{politician.name}'s model"
        Rails.logger.info "put tweets into #{politician.name}'s model"
        politician.tweets.concat(will_be_saved)
      end
    end
  end

  def self.get_tweet_more(start_id, last_id) #트윗들 : Array
    got_tweets = Twitter.user_timeline(screen_name, {:since_id => start_id, :max_id => last_date, :count => 200})
    if got_tweets.nil?
      return []
    else
      if got_tweets.count == 200
        got_tweets << get_tweet_more(start_id, got_tweets_tweets.last.id)
      end
      return got_tweets
    end
  end
end
