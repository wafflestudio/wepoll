#coding:utf-8
class Bill #법안모델
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes

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
  field :tags, type: Array #comma separated된 값들

  field :unregistered_coactor_names, type: Array #공동발의자이긴 한데 안잡힌 사람들

  #아래 값들은 타임라인 상에서 보이는건데, 이중 keyword는 tags에 포함될수도 있음.
  #개념정리가 좀 필요함
  field :keyword, type: String #issue 축약형
  field :issue, type: String #법안이 무슨 이슈에 관련된것인가? : ex) '출자총액제한 폐지', '사학법 개정'

  #=== Association ===
  belongs_to :initiator, class_name: "Politician", inverse_of: :initiate_bills #대표발의자
  has_and_belongs_to_many :coactors, class_name: "Politician" #공동발의자
  has_and_belongs_to_many :dissenters, class_name: "Politician" #법안 반대자
  has_and_belongs_to_many :supporters, class_name: "Politician" #법안 찬성자
end
