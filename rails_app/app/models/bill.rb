#coding:utf-8
class Bill #법안모델
  include Mongoid::Document

  #=== Mongoid fields ===
  field :title, type: String

  #=== Association ===
  belongs_to :initiator, class_name: "Politician", inverse_of: :initiate_bills #대표발의자
  has_and_belongs_to_many :coactors, class_name: "Politician" #공동발의자
  has_and_belongs_to_many :dissenters, class_name: "Politician" #법안 반대자
  has_and_belongs_to_many :supporters, class_name: "Politician" #법안 찬성자
end
