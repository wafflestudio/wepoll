class LinkReply
  include Mongoid::Document
  include Mongoid::Timestamps

	validates_associated :user
	validates_associated :timeline_entry

  #=== Mongoid fields ===
  field :body, type: String
  field :like, type: Integer, default: 0
  field :blame, type: Integer, default: 0 #신고

  belongs_to :user, :inverse_of => :link_replies
  belongs_to :timeline_entry, :inverse_of => :link_replies
end
