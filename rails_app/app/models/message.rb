#coding: utf-8
class Message
  include Mongoid::Document
  include Mongoid::Timestamps

	field :body, type: String
	field :tweet_feeed_id, type: String
	field :facebook_feed_id, type: String
  field :district, type: String
  field :like_count, type: Integer, default: 0
  field :blame_count, type: Integer, default: 0
	

	belongs_to :user
	belongs_to :preview

	belongs_to :politician
	belongs_to :pledge

	has_many :message_replies

  has_and_belongs_to_many :like_users, :class_name => "User", :inverse_of => :like_messages
  has_and_belongs_to_many :blame_users, :class_name => "User", :inverse_of => :blame_messages

  def posted_ago?
    ago = Time.now - created_at
    context = ""
    if (ago / 3600).to_i > 24
      context = ((ago / 3600) / 24).to_i.to_s + "일 전"
    elsif (ago / 3600).to_i > 0
      context = (ago / 3600).to_i.to_s + "시간 전"
    elsif (ago / 60) > 1
      context = (ago / 60).to_i.to_s + "분 전"
    else 
      context = "방금 전" 
    end
    context
  end

  def more_message?
    if replies.count > 3
      return true
    else
      return false
    end
  end

  def more_message
    replies.count - 3
  end

  def like(user)
    if self.like_users.include? user
      return false
    else
      self.like_count += 1
      self.like_users << user
      return self.save
    end
  end

  def blame(user)
    if self.blame_users.include? user
      return false
    else
      self.blame_count += 1
      self.blame_users << user
      return self.save
    end
  end
end
