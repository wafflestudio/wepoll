#coding:utf-8
class Bill #법안모델
  include Mongoid::Document

  RESULT_APPROVED = "approved" #가결
  RESULT_REJECTED = "rejected" #부결
  RESULT_DISPOSAL = "disposal" #폐기
  RESULT_WITHDRAW = "withdraw" #철회
  RESULT_EXPIRED  = "expired"  #임기만료 폐기

  #=== Mongoid fields ===
  field :title, type: String
  field :initiated_at, type: Date #발의일자
  field :voted_at, type: Date #표결일자
  field :complete, type: Boolean #표결여부 true : 의결, false : 계류
  field :result, type: String #표결결과
  field :commitee, type: String #소관위원회
  field :code, type: String #의안정보사이트 likms.assembly.go.kr 에서 쓰는 법안 코드
  field :number, type: Integer #국회에서 쓰이는 법안 번호
  field :summary, type: String

  #=== Association ===
  belongs_to :initiator, class_name: "Politician", inverse_of: :initiate_bills #대표발의자
  has_and_belongs_to_many :coactors, class_name: "Politician" #공동발의자
  has_and_belongs_to_many :dissenters, class_name: "Politician" #법안 반대자
  has_and_belongs_to_many :supporters, class_name: "Politician" #법안 찬성자
end
