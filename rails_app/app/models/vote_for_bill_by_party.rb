class VoteForBillByParty
  include Mongoid::Document

  belongs_to :bill, index: true

  field :party, :type => String
  # 찬성
  field :num_supporters, :type => Integer
  # 반대
  field :num_dissenters, :type => Integer
  # 출석만 한경우, 즉 기권 (기권표를 던지던지 표를 아예 던지지 않은 경우)
  field :num_attendees, :type => Integer
  # 부재 (출장, 휴가, 무단 결석 포함)
  field :num_absentees, :type => Integer

end
