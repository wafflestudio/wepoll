class TweetReply
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :in_reply_to_status_id, type: String
  field :in_reply_to_user_id, type: String
  field :in_reply_to_screen_name, type: String

  field :like_count, type: Integer, default: 0 # 추천
  field :blame_count, type: Integer, default: 0    # 신고

  field :vote_ips, type: Array, default: []


  belongs_to :user
  belongs_to :tweet
  has_and_belongs_to_many :like_users, :class_name => "User", :inverse_of => :like_tweet_replies
  has_and_belongs_to_many :blame_users, :class_name => "User", :inverse_of => :blame_tweet_replies


  def like(user)
    if self.like_users.include? user
      false
    else
      self.like_count += 1
      self.like_users << user
      self.save
    end
  end

  def blame(user)
    if self.blame_users.include? user
      false
    else
      self.blame_count += 1
      self.blame_users << user
      self.save
    end
  end

end
