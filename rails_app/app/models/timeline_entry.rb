#coding : utf-8
class TimelineEntry
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes
  include Mongoid::Paperclip

	validates_associated :user
	validates_presence_of :url,:posted_at

  #=== Mongoid fields ===
  field :comment, type: String
  field :url, type: String
  field :aux_url, type: String # image나 동영상
  field :link_type, type: String #NOTE:url이 가리키는 대상이 뭔지 구분하기 위해서 필요하다.
  field :posted_at, type:Time
  field :deleted, type: Boolean, default: false
  field :title, type: String
  field :is_good, type: Boolean, default: true #칭찬링크: true, 지적링크: false
  field :like_count, type: Integer, default:0 #공감수
  field :blame_count, type: Integer, default:0 #신고수
  field :tags, type: Array, default: []

  #=== Mongoid attach ===
  has_mongoid_attached_file :thumbnail,
    :styles => {:square48 => "48x48#"},
    :url => "/system/link_thumbnails/:id/:style.:extension",
    :path => Rails.root.to_s+"/public/system/link_thumbnails/:id/:style.:extension",
    :convert_options => { :all => '-strip -colorspace RGB'} #fucking IE

  def tag_text
  	text = ""
  	self.tags.each do |tag|
  		text += tag + "," 
  	end
  	text
  end

  def tag_text=(text)
		self.tags = text.split(",")	
  end

  #생성한 user
  belongs_to :user, :inverse_of => :timeline_entries

  #소속 정치인
  belongs_to :politician

  #댓글들
  has_many :link_replies, :inverse_of => :timeline_entry, :dependent => :destroy

  has_and_belongs_to_many :like_users, :class_name => "User", :inverse_of => :like_timeline_entries
  has_and_belongs_to_many :blame_users, :class_name => "User", :inverse_of => :blame_timeline_entries

  before_destroy :adjust_link_count_of_politician

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

  def more_link?
    if link_replies.count > 3
      return true
    else
      return false
    end
  end

  def more_link
    link_replies.count - 3
  end

  def adjust_link_count_of_politician
    self.politician.inc (self.is_good ? :good_link_count : :bad_link_count), -1
  end
end
