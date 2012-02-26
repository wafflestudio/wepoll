#coding : utf-8
class TimelineEntry
  include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::MultiParameterAttributes

	belongs_to :politician

  #=== Mongoid fields ===
  field :comment, type: String
  field :url, type: String
  field :link_type, type: String #NOTE:url이 가리키는 대상이 뭔지 구분하기 위해서 필요하다.
  field :posted_at, type:Time
  field :deleted, type: Boolean, default: false
end
