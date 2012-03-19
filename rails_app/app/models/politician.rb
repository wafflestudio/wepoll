#coding:utf-8
require Rails.root+'romanize.rb'
require 'csv'

class Politician #정치인 모델
  include Mongoid::Document
  include Mongoid::Paperclip
  include Mongoid::MultiParameterAttributes

  #=== Mongoid fields ===
  # 기본정보
  field :name, type: String
  field :party, type: String
  field :district, type: String #NOTE : 지역구를 따로 모델로 빼는건?
  field :candidate, type: Boolean, default: false #NOTE: 19대 후보인가 아닌가,19대에만 적용되는 플래그. 주의

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
  field :attendance, type: Integer, default: 0

  field :joint_initiate_bill_politicians, type: Array, default: []

  #타임라인 관련
  field :good_link_count, type: Integer, default: 0
  field :bad_link_count, type: Integer, default: 0

index :district

  #=== Mongoid attach ===
  has_mongoid_attached_file :profile_photo,
    :styles => {:square100 => "100x100#", :square160 => "160x160#"},
    :default_url => "/system/politician_profile_photos/anonymous_:style.gif",
    :url => "/system/politician_profile_photos/:id/:style.:extension",
    :path => Rails.root.to_s+"/public/system/politician_profile_photos/:id/:style.:extension"

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
    timeline_entries.where(:is_good => true).desc("like_count").limit(1)
  end

  def most_bad_link
    timeline_entries.where(:is_good => false).desc("like_count").limit(1)
  end

  def initiate_bills_categories
    initiate_bills.map {|b| b.commitee}.reject { |bt| bt.nil? }.sort.inject([]) do |s,x|
      s.last.nil? ? s<<[x,1] : s.last.first == x ? s[0...-1] << [s.last.first, s.last.last+1] : s << [x,1]
    end
  end

  def is_18?
    if elections.include?(18)
      true
    else
      false
    end
  end

  def self.calculate_joint_initiate
    puts "=== 공동발의 일치도 계산 ==="
    Politician.all.each do |politician|
      print "#{politician.name}\t"
      h = {}

      politician.initiate_bills.each do |bill|
        co = bill.coactors.reject {|coactor| coactor.id == politician.id}
        co.each {|coactor| h[coactor.id] = (h[coactor.id] || 0) + 1 }
        bill.unregistered_coactor_names.each {|name| h[name] = (h[name] || 0)+1} if !bill.unregistered_coactor_names.nil?
      end

      politician.joint_initiate_bill_politicians = h.to_a.sort {|x,y| y[1] <=> x[1]}
      politician.save
    end
    puts "=== 공동발의 일치도 계산 완료 ==="
  end

  def self.calculate_attendance
    puts "=== 출석률 계산 ==="
    csvs_folder = ["csvs","csvs2","csvs3"]
    Politician.all.each do |politician|
      name = politician.name.romanize
      csvs_folder.each do |csvs|
        if File.exists?(Rails.root + "init_data/profile_csvs/#{csvs}/profile2_#{name}.csv")
          total = 0
          CSV.foreach(Rails.root + "init_data/profile_csvs/#{csvs}/profile2_#{name}.csv", :encoding => "UTF-8") do |csv|
            name = csv[0]
            party = csv[3].split("/").first
            if party == "한나라당"
              party = "새누리당"
            elsif party == "민주당"
              party = "민주통합당"
            end
            if politician != Politician.where(name: name, party: party).first
              puts "###ERROR### #{politician.name.romanize} #{name} #{party}" 
              next
            end
            sum = 0
            list = csv[9].split(")")
            puts politician.name
            list.each do |elem|
              e = elem[13..25]
              q = e.match("[0-9]+").to_s.to_i
              total += q

              elem = elem[8..12]
              puts elem
              p = elem.match("[0-9]+").to_s.to_i
              sum += p
              printf "#{sum} / #{total}\n"
            end
            puts (total / Float(sum) * 100).to_i.to_s
            politician.attendance = (total / Float(sum) * 100).to_i
            politician.save
          end
        end
      end
    end
    puts "=== 출석률 계산 완료 ==="
  end
end
