#coding:utf-8
require Rails.root+'romanize.rb'
require 'csv'

require 'iconv'
require 'open-uri'
require 'nokogiri'

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
  field :detail_promises, type: Array, default: []
  field :attendance, type: Array, default: (1..18).to_a.inject([]) {|a,x| a[x] = 0;a}
  field :number, type: Integer, default: 0 # 기호 n번

  # 법안관련
  field :joint_initiate_bill_politicians, type: Array, default: (1..18).to_a.inject([]) {|a,x| a[x] = [];a}
  field :crawl_init_bill_completed, type: Boolean, default: false


  #한마디 관련
  field :message_count, type: Integer, default: 0

  #타임라인 관련
  field :good_link_count, type: Integer, default: 0
  field :bad_link_count, type: Integer, default: 0

  index :district
  index :name
  index :party
  index :candidate

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

  #한마디
  has_many :messages
  has_many :pledges

  def total_replies
    self.tweets.map {|t| t.tweet_replies}.flatten
  end

  def most_good_link
    timeline_entries.where(:is_good => true).desc("like_count").limit(1)
  end

  def most_bad_link
    timeline_entries.where(:is_good => false).desc("like_count").limit(1)
  end

  def initiate_bills_categories(age)
    initiate_bills.where(:age => age).map {|b| b.commitee}.reject { |bt| bt.nil? }.sort.inject([]) do |s,x|
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

  def calculate_joint_initiate(age=18)
    return unless elections.include? age
    h = {}

    initiate_bills.where(:age => age).each do |bill|
      co = bill.coactors.reject {|coactor| coactor.id == id || !coactor.elections.include?(age)}
      co.each {|coactor| h[coactor.id] = (h[coactor.id] || 0) + 1 }
      bill.unregistered_coactor_names.each {|name| h[name] = (h[name] || 0)+1} if !bill.unregistered_coactor_names.nil?
    end

    joint_initiate_bill_politicians[age] = h.to_a.sort {|x,y| y[1] <=> x[1]}
    save
  end

  def self.calculate_joint_initiate
    puts "=== 공동발의 일치도 계산 ==="
    (1..18).to_a.reverse.each do |age|
      puts "\n=== #{age}대 ==="
      Politician.all.each do |politician|
        print politician.name+"\t"
        politician.calculate_joint_initiate(age)
      end
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
              party = "민주통합"
            end
            party = party[0..3]
            if politician != Politician.where(name: name, party: party).first
              puts "###ERROR### #{politician.name.romanize} #{name} #{party}" 
              next
            end
            sum = 0
            list = csv[9].split(")")
            #puts politician.name
            list.each do |elem|
              e = elem[13..25]
              q = e.match("[0-9]+").to_s.to_i
              total += q

              elem = elem[8..12]
              #puts elem
              p = elem.match("[0-9]+").to_s.to_i
              sum += p
              #printf "#{sum} / #{total}\n"
            end
            #puts (total / Float(sum) * 100).to_i.to_s
            politician.attendance = (total / Float(sum) * 100).to_i
            politician.save
          end
        end
      end
    end
    puts "=== 출석률 계산 완료 ==="
  end

  def crawl_initiated_bills
    self.update_attribute(:crawl_init_bill_completed, false)
    iconv = Iconv.new("utf-8", "euc-kr")
    doc_raw = ""
    begin
      doc_raw = iconv.iconv(Net::HTTP.post_form(URI.parse("http://likms.assembly.go.kr/bill/jsp/BillSearchResult.jsp"), {:PAGE_SIZE=>2000, :PROPOSER=>self.name.encode("euc-kr"), :PROPOSE_GUBN=>"대표발의".encode("euc-kr"), :AGE_FROM=>1, :AGE_TO=>18}).body)
    rescue
      puts "=====ERR : #{self.name} search failed====="
      return
    end

    tmp_name = self.name.romanize
    c = 1
    while File.exists? "raw_data/law_list_#{tmp_name}_page1.html"
      tmp_name = self.name.romanize+"_#{c}"
      c+=1
    end

    f = File.open("raw_data/law_list_#{tmp_name}_page1.html", "w")
    f.write doc_raw
    f.close

    doc = Nokogiri::HTML(doc_raw)

    number_strip_regex = /총(\d+)건이 검색되었습니다/
    title_strip_regex = /(.*)\(.*\)$/
    code_strip_regex = /GoDetail\(\'([a-z_A-Z0-9]+)\'\)/

    #발의건수
    elem = doc.xpath("/html/body/table[2]/tbody/tr[2]/td[1]")[0]
    s = elem.children[1].children[0].children[0].children[2].children[3].children[0].to_s.strip
    init_num = s.match(number_strip_regex)[1].to_i

    puts "=====#{self.name} #{init_num}건====="


    CSV.open(Rails.root+"init_data/law_csvs/csvs4/laws_#{name.romanize}.csv", "w") do |csv|
      1.upto(init_num).each do |i|
        row=doc.xpath("/html/body/table[2]/tbody/tr[2]/td/table/tbody/tr[4]/td[2]/table/tbody/tr[#{i*2}]")
        break if row.xpath("td").count == 1
        #의안번호
        num = row.xpath("td[1]").children[0].to_s.strip
        #의안제목(의원명 포함)
        strip_title = title = row.xpath("td[2]/a").attr('title').to_s
        #의안코드(사이트내부적으로 쓰이는듯)
        code = row.xpath("td[2]/a").attr("href").to_s.match(code_strip_regex)[1]
        #의안제목
        tmp = title.match(title_strip_regex)
        strip_title = tmp[1] unless tmp.nil?
        puts "##{i} #{strip_title} #{code}"
        #처리 플래그 (처리=true, 계류=false)
        complete = row.xpath("td[2]/img").attr("src").to_s.split("/").last == "icon_02.gif"
        #발의일자
        init_date = row.xpath("td[4]").children[0].to_s.strip
        #의결일자
        complete_date = row.xpath("td[5]").children[0].to_s.strip
        #의결결과
        result = row.xpath("td[6]").children[0].to_s.strip

        #의안 써머리
        doc2_raw = ""
        if File.exists? "raw_data/law_summary_#{code}.html"
          doc2_raw = File.read("raw_data/law_summary_#{code}.html")
        else
          begin
            sleep(1)
            doc2_raw = iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/SummaryPopup.jsp?bill_id=#{code}").read)
            f = File.open("raw_data/law_summary_#{code}.html", "w")
            f.write doc2_raw
            f.close
          rescue Exception => e
            puts "=====ERR : #{code} summary failed, #{e.message}  ====="
          end
        end
        doc2 = Nokogiri::HTML(doc2_raw)
        summary = doc2.xpath("/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[2]/span[2]").inner_text.strip

        #위원회
        doc3_raw = ""
        if File.exists? "raw_data/law_detail_#{code}.html"
          doc3_raw = File.read("raw_data/law_detail_#{code}.html")
        else
          begin
            sleep(1)
            doc3_raw = open("http://likms.assembly.go.kr/bill/jsp/BillDetail.jsp?bill_id=#{code}").read
            f = File.open("raw_data/law_detail_#{code}.html", "w")
            f.write doc3_raw
            f.close
          rescue Exception => e
            puts "=====ERR : #{code} detail failed, #{e.message}====="
          end
        end
        doc3 = Nokogiri::HTML(doc3_raw)
        commitee = doc3.xpath("/html/body/table[2]/tbody/tr[2]/td/table/tbody/tr[4]/td[2]/table/tbody/tr[6]/td[2]/table/tbody/tr[2]/td/div").children[0].to_s

        #발의의원
        doc4_raw = ""
        if File.exists? "raw_data/law_coactors_#{code}.html"
          doc4_raw = File.read "raw_data/law_coactors_#{code}.html"
        else
          begin
            sleep(1)
            doc4_raw = 
            begin
              iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/CoactorListPopup.jsp?bill_id=#{code}").read)
            rescue Iconv::IllegalSequence => e 
              open("http://likms.assembly.go.kr/bill/jsp/CoactorListPopup.jsp?bill_id=#{code}").read.encode("UTF-8")
            end

            f = File.open("raw_data/law_coactors_#{code}.html", "w")
            f.write doc4_raw
            f.close
          rescue Exception => e
            puts "=====ERR : #{code} coactors failed, #{e.message}====="
          end
        end
        doc4 = Nokogiri::HTML(doc4_raw)
        coactors = doc4.xpath("/html/body/table[2]/tr[2]/td[1]/table/tr[2]/td[2]/table/tr[1]/td").map {|elem| elem.inner_text.to_s}

        commitee = commitee[0.. commitee.index("위원회")] if commitee.index("위원회") #소관위원회
        case commitee
        when "외교통상통일"
          commitee = "외교통상"
        when "교육과학기술"
          commitee = "교육과학"
        when "문화체육관광방송통신"
          commitee = "문화∙미디어"
        when "농림수산식품"
          commitee = "농림수산"
        when "법제사법"
          commitee = "사법"
        when "정무"
          commitee = "국정총괄"
        when "정보"
          commitee = "국가정보"
        when "기획재정"
          commitee = "재정"
        when "지식경제"
          commitee = "경제"
        end

        csv << [name, init_num, num, code, strip_title, (complete ? "의결" : "계류"), init_date, complete_date, result, summary, coactors.join(","), commitee]

        only_names = []

        duplicated_coactors_name = []
        coactors.each do |coactor|
          duplicated_coactors_name << coactor if Politician.where(:name => coactor).count > 1
        end

        coactors = coactors.map {|name| p1 = Politician.where(:name => name).first; only_names << name if p1.nil?; p1}.reject {|p2| p2.nil? || self.id == p2.id || Politician.where(name: name).count != 1 }

        bill = Bill.new(:title => strip_title, :number => num, :code => code, :initiated_at => Date.parse(init_date), :result => result, :commitee => commitee, :initiator => self, :summary => summary, :complete => complete, :unregistered_coactor_names => only_names, :duplicated_coactors_name => duplicated_coactors_name, :coactors => coactors)
        bill.voted_at = Date.parse(complete_date) unless (complete_date.nil? || complete_date.length == 0)

        bill.save
        self.crawl_init_bill_completed = true
        self.save
        bill.calculate_age

      end #end of each law row
    end #end of CSV
  end

  def __restore_init_bill_result__
		code_strip_regex = /GoDetail\(\'([a-z_A-Z0-9]+)\'\)/

    csv_file_path = Dir.glob("init_data/law_csvs/csvs*/laws_#{name.romanize}.csv")[0]
    (puts "File doesn't exist"; return -1) unless csv_file_path && File.exists?(csv_file_path)
    CSV.foreach csv_file_path, :encoding => "UTF-8" do |csv|
      code = csv[3]
      b = Bill.where(:code => code).first
      if b == nil
        puts code + " doesn't exist"
      else
        b.update_attribute(:result, csv[8])
      end
    end
  end
end
