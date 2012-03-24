#coding:utf-8
class Bill #법안모델
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes

  AGE = []
  AGE[0]  = [Date.parse("1948.5.31"),Date.parse("1950.5.30")]
  AGE[1]  = [Date.parse("1950.5.31"),Date.parse("1954.5.30")]
  AGE[2]  = [Date.parse("1954.5.31"),Date.parse("1958.5.30")]
  AGE[3]  = [Date.parse("1958.5.31"),Date.parse("1960.7.28")]
  AGE[4]  = [Date.parse("1960.7.29"),Date.parse("1961.5.16")]
  AGE[5]  = [Date.parse("1963.12.17"),Date.parse("1967.6.30")]
  AGE[6]  = [Date.parse("1967.7.1"),Date.parse("1971.6.30")]
  AGE[7]  = [Date.parse("1971.7.1"),Date.parse("1972.10.17")]
  AGE[8]  = [Date.parse("1973.3.12"),Date.parse("1979.3.11")]
  AGE[9]  = [Date.parse("1979.3.12"),Date.parse("1980.10.27")]
  AGE[10] = [Date.parse("1981.4.11"),Date.parse("1985.4.10")]
  AGE[11] = [Date.parse("1985.4.11"),Date.parse("1988.5.29")]
  AGE[12] = [Date.parse("1988.5.30"),Date.parse("1992.5.29")]
  AGE[13] = [Date.parse("1992.5.30"),Date.parse("1996.5.29")]
  AGE[14] = [Date.parse("1996.5.30"),Date.parse("2000.5.29")]
  AGE[15] = [Date.parse("2000.5.30"),Date.parse("2004.5.29")]
  AGE[16] = [Date.parse("2004.5.30"),Date.parse("2008.5.29")]
  AGE[17] = [Date.parse("2008.5.30"),Date.parse("2012.5.29")]


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
  field :age, type: Integer #언제 ''발의''된 법안인가?

  field :unregistered_coactor_names, type: Array #공동발의자이긴 한데 안잡힌 사람들
  #=== FOR DUPLICATE NAME ===
  field :duplicated_coactors_name, :type => Array, default: [] #공동발의자이긴 한데, 디비에 두명이상 존재하는 인간들

  #아래 값들은 타임라인 상에서 보이는건데, 이중 keyword는 tags에 포함될수도 있음.
  #개념정리가 좀 필요함
  field :keyword, type: String #issue 축약형
  field :issue, type: String #법안이 무슨 이슈에 관련된것인가? : ex) '출자총액제한 폐지', '사학법 개정'

  #=== Association ===
  belongs_to :initiator, class_name: "Politician", inverse_of: :initiate_bills #대표발의자
  has_and_belongs_to_many :coactors, class_name: "Politician" #공동발의자
  has_and_belongs_to_many :dissenters, class_name: "Politician" #법안 반대자
  has_and_belongs_to_many :supporters, class_name: "Politician" #법안 찬성자
  has_and_belongs_to_many :absentees, class_name: "Politician" # 본회의 부재자
  has_and_belongs_to_many :attendees, class_name: "Politician" # 표결 기권자

  def self.calculate_age
    Bill.all.each {|bill| bill.calculate_age}
  end

  def calculate_age
    update_attribute(:age, (AGE.find_index {|s,f| s <= initiated_at && initiated_at <= f })+1) if initiated_at
  end
end
