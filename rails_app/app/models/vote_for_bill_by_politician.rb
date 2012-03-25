#coding:utf-8
class VoteForBillByPolitician
  include Mongoid::Document
  
  belongs_to :bill
  belongs_to :politician

  field :value, :type => String, default: "해당없음"

  
end
