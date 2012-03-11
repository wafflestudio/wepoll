class LinkReply
  include Mongoid::Document
  include Mongoid::Timestamps

	validates_associated :user
	validates_associated :timeline_entry

  #=== Mongoid fields ===
  field :body, type: String
  field :like_count, type: Integer, default: 0
  field :blame_count, type: Integer, default: 0 #신고

  belongs_to :user, :inverse_of => :link_replies
  belongs_to :timeline_entry, :inverse_of => :link_replies
  has_and_belongs_to_many :like_users, :class_name => "User", :inverse_of => :like_link_replies
  has_and_belongs_to_many :blame_users, :class_name => "User", :inverse_of => :blame_link_replies

  def like(user)
    if self.like_users.include? user
      false
    else
      self.like_count += 1
      self.like_users << user
      return self.save
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
