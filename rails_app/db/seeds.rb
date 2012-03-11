#coding : utf-8
require 'csv'
require 'mongoid'
require 'nokogiri'

require Rails.root + 'romanize.rb'

period = []
period[0]  = [Date.parse("1948.5.31"),Date.parse("1950.5.30")]
period[1]  = [Date.parse("1950.5.31"),Date.parse("1954.5.30")]
period[2]  = [Date.parse("1954.5.31"),Date.parse("1958.5.30")]
period[3]  = [Date.parse("1958.5.31"),Date.parse("1960.7.28")]
period[4]  = [Date.parse("1960.7.29"),Date.parse("1961.5.16")]
period[5]  = [Date.parse("1963.12.17"),Date.parse("1967.6.30")]
period[6]  = [Date.parse("1967.7.1"),Date.parse("1971.6.30")]
period[7]  = [Date.parse("1971.7.1"),Date.parse("1972.10.17")]
period[8]  = [Date.parse("1973.3.12"),Date.parse("1979.3.11")]
period[9]  = [Date.parse("1979.3.12"),Date.parse("1980.10.27")]
period[10] = [Date.parse("1981.4.11"),Date.parse("1985.4.10")]
period[11] = [Date.parse("1985.4.11"),Date.parse("1988.5.29")]
period[12] = [Date.parse("1988.5.30"),Date.parse("1992.5.29")]
period[13] = [Date.parse("1992.5.30"),Date.parse("1996.5.29")]
period[14] = [Date.parse("1996.5.30"),Date.parse("2000.5.29")]
period[15] = [Date.parse("2000.5.30"),Date.parse("2004.5.29")]
period[16] = [Date.parse("2004.5.30"),Date.parse("2008.5.29")]
period[17] = [Date.parse("2008.5.30"),Date.parse("2012.5.29")]

ommitted_names = []

#==== 정치인 ====
puts "-------- 18대 국회의원 생성중 --------"
cnt = 0
CSV.foreach(Rails.root+"init_data/politicians_18.csv", :encoding => "UTF-8") do |csv|
  district = csv[3]
  name = csv[4]
  printf "#{name}\t"
  party = csv[5]
  count = 0
  count = (c=csv[8][0]; c=='초' ? 1 : c=='재' ? 2 : c.to_i) unless csv[8].nil?
  birth = Date.parse("19"+csv[9]) unless csv[9].nil?

  military = nil
  if csv[10] == '군필'
    complete_class = csv[11]
    military = "#{complete_class[0...2]} #{complete_class[2..-1]} #{csv[13]}"
  elsif csv[9] == '면제'
    military = "면제#{csv[13]}"
  end

  name_romanize = name.romanize
  profile_photo_path = Dir.glob("init_data/profile_photos/*.jpg").select {|p| p.include? name_romanize}[0]

  tweet_name = nil
  if File.exists?(Rails.root+"init_data/naver_result/naver_#{name_romanize}.csv")
    CSV.foreach(Rails.root+"init_data/naver_result/naver_#{name_romanize}.csv", :encoding => "UTF-8") do |tw|
      tweet_name = tw[9].slice(19..-1) unless tw[9].nil?
    end
  end

  p = Politician.new(:name => name,
                     :party => party,
                     :election_count => count,
                     :birthday => birth,
                     :military => military,
                     :district => district,
                     :tweet_name => tweet_name)
  cnt += 1
  p.profile_photo = File.open(Rails.root + profile_photo_path) unless profile_photo_path.nil?
  puts "#{name} photo doesn't exist" if profile_photo_path.nil?

  csv_file_path = Dir.glob("init_data/profile_csvs/csvs*/profile2_#{name_romanize}.csv")[0]
  (p.save! ; ommitted_names << name ; next) if csv_file_path.nil?
  (p.save! ; ommitted_names << name ; next) if File.stat(csv_file_path).size == 0

  CSV.foreach(csv_file_path, :encoding => "UTF-8")do |csv2|
    t = csv2[3].split("/").last.match(/\(.*\)$/)
    t = t.to_s
    p.elections = t.scan(/\d+/).map {|s| s.to_i}
  end
  p.save!
end
puts "\n총 #{cnt}명"
puts "세부 프로필 빠진 사람 : #{ommitted_names.join(",")}"

dump_file_exist = false
if File.exists? Rails.root+"bill_dump"
  dump_file_exist = true
elsif File.exists? Rails.root+"bill_dump.gz"
  %x(gunzip -c #{Rails.root+"bill_dump.gz"} > #{Rails.root+"bill_dump"})
  dump_file_exist = true
end

puts "-------- 발의법안 처리중 --------"
if dump_file_exist
  puts "-------- 기존 dump 파일에서 생성 --------"
  dumps = File.read(Rails.root+"bill_dump").split("!averyspecialandlongstringwhichwouldnotbeappearedinthistextfilekk!")
  cnt = 0
  total = dumps.count

  dumps.each do |dump|
    h = YAML::load(dump)

    party, name = (h.delete :initiator_name).split(" ")
    h[:initiator_id] = Politician.where(:party => party, :name => name).first.id

    array_from_coactor_names = h.delete :coactor_names
    h[:coactor_ids] = array_from_coactor_names.map {|t| party,name=t.split(" ");Politician.where(:party => party, :name => name).first.id} unless array_from_coactor_names.nil?
    h[:supporter_ids] = (h.delete :supporter_names).map {|t| party,name=t.split(" ");Politician.where(:party => party, :name => name).first.id}
    h[:dissenter_ids] = (h.delete :dissenter_names).map {|t| party,name=t.split(" ");Politician.where(:party => party, :name => name).first.id}

    bill = Bill.create(h)

    #진행상황표시
    printf "\r%5d/%5d (%.2f%%) #{bill.title}                         ", cnt+=1, total, cnt.to_f/total*100.0
  end
end

(exit 0) if dump_file_exist

=begin
#==== 법안 ====
c2 = 0
puts "-------- csv 파일에서 생성 --------"
f = File.open(Rails.root+"duplicated_politician.txt", "w") # *** 동명이인 처리, 법안 번호, 이름 저장하고 수작업으로 직접 입력
CSV.foreach(Rails.root+"init_data/politicians_18.csv", :encoding => "UTF-8") do |csv|
  name = csv[4]
  party = csv[5]
  p = Politician.where(:name => name, :party => party).first #XXX : 동명이인 어떻게 처리 **** 처리 완료
  puts "#{name} doesn't exist!! " if p.nil?
  name_romanize = name.romanize
  csv_file_path = Dir.glob("init_data/law_csvs/csvs*/laws_#{name_romanize}.csv")[0]
  printf "#{name}(#{c2+=1}) 발의한 법안..."
  (puts "0개"; next) if csv_file_path.nil?

  law_count = 0
  CSV.foreach(csv_file_path, :encoding => "UTF-8") do |csv2|
    number = csv2[2] #법안번호 (국회에서 쓰는것)
    code = csv2[3] #법안코드 (의안정보사이트 내에서 쓰는것)
    title = csv2[4] #법안제목
    complete = csv2[5] == '의결'
    init_date = csv2[6]

    #법안 제안 날짜중에 이 정치인이 발의할 수 없는 날짜인것은 제외
    tmp_date = Date.parse init_date
    age = 18
    period.reverse_each do |s,f|
      break if tmp_date>=s && tmp_date<=f
      age-=1
    end

    if p.nil?
      puts "Politician is nil!!"
    end

    next if p.elections.nil? || !(p.elections.include?(age))

    complete_date = csv2[7]
    result = ""
    if csv2[8].index "가결"
      result = Bill::RESULT_APPROVED
    elsif csv2[8].index "부결"
      result = Bill::RESULT_REJECTED
    elsif csv2[8].index "임기만료폐기"
      result = Bill::RESULT_EXPIRED
    elsif csv2[8].index "철회"
      result = Bill::RESULT_WITHDRAW
    elsif csv2[8].index "폐기"
      result = Bill::RESULT_DISPOSAL
    end

    summary = csv2[9]
    coactors = (csv2[10] || "").split(",") #공동발의자
    commitee = nil
    commitee = csv2[11][0...csv2[11].index("위원회")] if csv2[11].index("위원회") #소관위원회
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

    #XXX : 동명이인 어떻게 처리 *** 동명이인 처리
    #XXX : 이름만 등록된 껍데기 국회의원을 만든다
    only_names = []

    coactors.each do |coactor|
      puts "#{title},#{code},#{name}" if Politician.where(:name => name).count != 1
      f.write "#{title},#{code},#{name}" if Politician.where(:name => name).count != 1
    end

    coactors = coactors.map {|name| p1 = Politician.where(:name => name).first; only_names << name if p1.nil?; p1}.reject {|p2| p2.nil? || p.id == p2.id || Politician.where(name: name).count != 1 }

    # *** : 동명이인만 따로 정리. 나중에 직접 입력

    b = Bill.new(:title => title,
                 :initiated_at => Date.parse(init_date),
                 :complete => complete,
                 :result => result,
                 :commitee => commitee,
                 :number => number,
                 :code => code,
                 :coactors => coactors,
                 :unregistered_coactor_names => only_names,
                 :initiator => p,
                 :summary => summary)
    b.voted_at = Date.parse(complete_date) unless (complete_date.nil? || complete_date.length == 0)
    b.save!
    law_count += 1
  end
  puts "#{law_count}개"
end
f.close
#=== 법안 입력 끝 ===

#==== 법안에 대한 찬성 반대 ====
#==== 반대는 raw data에 없어서 구현이 안됨
puts "법안에 대한 찬성 반대 입력 중"
puts "============================="

f = File.open(Rails.root+"duplicated_supporters.txt", "w")
File.open(Rails.root + "init_data/bill_codes.txt", "r").each do |line|
  code = line.sub("\n", "")
  file_name = "#{code}.html"

  bill = Bill.where(:code => code).first

  if bill.nil?
    puts "법안 code=#{code} 존재하지 않습니다."
  else
    #find containing dir
    fname = Dir.glob(Rails.root+"raw_data*/law_coactors_#{file_name}")[0]

    if fname
      raw_data = File.open(fname).read
      doc = Nokogiri::HTML(raw_data)
      names = doc.xpath("html/body/table[4]/tr[2]/td[1]/table/tr[2]/td[2]/table//td").map {|td| td.inner_text}.reject {|txt| txt.length == 0}

      # *** 동명이인 처리
      names.each do |name|
        f.write "#{bill.title},#{code},#{name}" if Politician.where(:name => name).count != 1
      end

      bill.supporters = names.map {|name| Politician.where(:name => name).first}.reject {|temp| temp.nil? || Politician.where(name: name).count != 1 }

      puts "==== 법안찬성자 ===="
      puts names.join(",")
      puts(bill.save ? "==== 성공 ====" : "==== 실패 ====")
    else
      puts "파일 law_coactors_#{file_name} 이 존재하지않습니다."
    end
  end
end

Politician.calculate_joint_initiate
=end
