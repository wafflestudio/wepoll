#coding:utf-8
class Bill #법안모델
  include Mongoid::Document

  #=== Mongoid fields ===
  field :title, type: String
  field :initiated_at, type: Date #발의일자
  field :voted_at, type: Date #표결일자
  field :result, type: Boolean #표결결과

  #=== Association ===
  belongs_to :initiator, class_name: "Politician", inverse_of: :initiate_bills #대표발의자
  has_and_belongs_to_many :coactors, class_name: "Politician" #공동발의자
  has_and_belongs_to_many :dissenters, class_name: "Politician" #법안 반대자
  has_and_belongs_to_many :supporters, class_name: "Politician" #법안 찬성자
end
