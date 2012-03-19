class Message
  include Mongoid::Document
  include Mongoid::Timestamps

	field :body, type: String
	field :tweet_feeed_id, type: String
	field :facebook_feed_id, type: String
	

	belongs_to :user
	belongs_to :preview

	has_many :replies, inverse_of: :parent_message, :class_name => 'Message'
	belongs_to :parent_message, inverse_of: :replies, :class_name => 'Message'
end
