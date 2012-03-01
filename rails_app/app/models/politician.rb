#coding:utf-8
class Politician #정치인 모델
  include Mongoid::Document
  include Mongoid::Paperclip

  #=== Mongoid fields ===
  # 기본정보
  field :name, type: String
  field :party, type: String
  field :district, type: String #NOTE : 지역구를 따로 모델로 빼는건?

  # 프로필정보
  field :military, type: String
  field :elections, type: Array, default: [] #당선된 대수 ex : [15,16,18]
  field :election_count, type: Integer #NOTE:120210 데이터에는 당선횟수밖에 없어
  field :birthday, type: Date
  field :tweet_name, type: String
  field :job, type: String
  field :education, type: String
  field :experiences, type: String
  field :promises, type: Array, default: []

  field :joint_initiate_bill_politicians, type: Array, default: []

  #타임라인 관련
  field :good_link_count, type: Integer, default: 0
  field :bad_link_count, type: Integer, default: 0

  #=== Mongoid attach ===
  has_mongoid_attached_file :profile_photo,
    :styles => {:square100 => "100x100#"},
    :url => "/system/politician_profile_photos/:id/:style.:extension",
    :path => Rails.root.to_s+"/public/system/politician_profile_photos/:id/:style.:extension",
    :convert_options => { :all => '-strip -colorspace RGB'} #fucking IE

  #=== Association ===
  # maybe this politician has a user account
  belongs_to :user
  # 법안관련
  has_many :initiate_bills, class_name: "Bill", inverse_of: :initiator

  # 트윗 관련
  has_many :tweets

  #타임라인 관련
  has_many :timeline_entries

  def total_replies
    self.tweets.map {|t| t.tweet_replies}.flatten
  end

  def most_good_link
    timeline_entries.where(:is_good => true).desc("like").limit(1)
  end

  def most_bad_link
    timeline_entries.where(:is_good => false).desc("like").limit(1)
  end

  def initiate_bills_categories
    bills_commitees = initiate_bills.map {|b| b.commitee}.sort

    return {} if bills_commitees.count == 0
    return {"#{bills_commitees[0]}" => 1} if bills_commitees.count == 1

    cnt = 0
    h = {}
    0.upto(bills_commitees.count-2) do |i|
      if bills_commitees[i] == bills_commitees[i+1]
        cnt +=1
      else
        h[bills_commitees[i]] = cnt+1
        cnt = 0
      end
    end

    if bills_commitees[-1] == bills_commitees[-2]
      h[bills_commitees[-1]] = cnt+1
    else
      h[bills_commitees[-1]] = 1
    end

    h
  end

  def self.calculate_joint_initiate
    puts "=== 공동발의 일치도 계산 ==="
    Politician.all.each do |politician|
      h = {}
      politician.initiate_bills.each do |bill|
        bill.coactors.each {|coactor| h[coactor.id] = (h[coactor.id] || 0) + 1 }
        bill.unregistered_coactor_names.each {|name| h[name] = (h[name] || 0)+1}
      end

      politician.joint_initiate_bill_politicians = h.to_a.sort {|x,y| y[1] <=> x[1]}
      politician.save
      print "#{politician.name}\t"
    end
    puts "=== 공동발의 일치도 계산 완료 ==="
  end
end
