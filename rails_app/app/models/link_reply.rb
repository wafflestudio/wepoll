#encoding: utf-8
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
      #link-re
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

end
