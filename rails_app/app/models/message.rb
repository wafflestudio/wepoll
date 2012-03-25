#coding: utf-8
class Message
  include Mongoid::Document
  include Mongoid::Timestamps

	field :body, type: String
	field :tweet_feeed_id, type: String
	field :facebook_feed_id, type: String
  field :district, type: String
	

	belongs_to :user
	belongs_to :preview

	belongs_to :politician
	belongs_to :pledge

	has_many :message_replies

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
end
