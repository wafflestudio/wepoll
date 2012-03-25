class MessageReply
  include Mongoid::Document
  include Mongoid::Timestamps

	field :body, type: String

	belongs_to :user
  belongs_to :message
end
