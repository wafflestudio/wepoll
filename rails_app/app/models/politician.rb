#coding:utf-8
class Politician #정치인 모델
  include Mongoid::Document

  #=== Mongoid fields ===
  field :name, type: String

  #=== Association ===
  # maybe this politician has a user account
  belongs_to :user
  # 법안관련
  has_many :initiate_bills, class_name: "Bill", inverse_of: :initiator
end
