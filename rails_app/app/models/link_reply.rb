class LinkReply
  include Mongoid::Document
  include Mongoid::Timestamps

	validates_associated :user
	validates_associated :timeline_entry

  #=== Mongoid fields ===
  field :body, type: String
  field :like, type: Integer
  field :blame, type: Integer #신고

  belongs_to :user
  belongs_to :timeline_entry
end
