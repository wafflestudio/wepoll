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
  field :link_type, type: String #NOTE:url이 가리키는 대상이 뭔지 구분하기 위해서 필요하다.
  field :posted_at, type:Time
  field :deleted, type: Boolean, default: false
  field :title, type: String
  field :is_good, type: Boolean, default: true #칭찬링크: true, 지적링크: false
  field :like, type: Integer, default:0 #공감수
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
  		text += tag + "\n" 
  	end
  	text
  end

  def tag_text=(text)
		self.tags = text.split("\n")	
  end

  #생성한 user
  belongs_to :user

  #소속 정치인
  belongs_to :politician

end
