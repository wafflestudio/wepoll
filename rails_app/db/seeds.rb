#coding : utf-8
require 'csv'
require 'mongoid'
require 'nokogiri'

period = {}
period[1]  = [Date.parse("1948.5.31"),Date.parse("1950.5.30")]
period[2]  = [Date.parse("1950.5.31"),Date.parse("1954.5.30")]
period[3]  = [Date.parse("1954.5.31"),Date.parse("1958.5.30")]
period[4]  = [Date.parse("1958.5.31"),Date.parse("1960.7.28")]
period[5]  = [Date.parse("1960.7.29"),Date.parse("1961.5.16")]
period[6]  = [Date.parse("1963.12.17"),Date.parse("1967.6.30")]
period[7]  = [Date.parse("1967.7.1"),Date.parse("1971.6.30")]
period[8]  = [Date.parse("1971.7.1"),Date.parse("1972.10.17")]
period[9]  = [Date.parse("1973.3.12"),Date.parse("1979.3.11")]
period[10] = [Date.parse("1979.3.12"),Date.parse("1980.10.27")]
period[11] = [Date.parse("1981.4.11"),Date.parse("1985.4.10")]
period[12] = [Date.parse("1985.4.11"),Date.parse("1988.5.29")]
period[13] = [Date.parse("1988.5.30"),Date.parse("1992.5.29")]
period[14] = [Date.parse("1992.5.30"),Date.parse("1996.5.29")]
period[15] = [Date.parse("1996.5.30"),Date.parse("2000.5.29")]
period[16] = [Date.parse("2000.5.30"),Date.parse("2004.5.29")]
period[17] = [Date.parse("2004.5.30"),Date.parse("2008.5.29")]
period[18] = [Date.parse("2008.5.30"),Date.parse("2012.5.29")]

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

  profile_photo_path = Dir.glob("init_data/profile_photos/*.jpg").select {|p| p.include? name}[0]

  tweet_name = nil
  if File.exists?(Rails.root+"init_data/naver_result/naver_#{name}.csv")
    CSV.foreach(Rails.root+"init_data/naver_result/naver_#{name}.csv", :encoding => "UTF-8") do |tw|
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

  csv_file_path = Dir.glob("init_data/profile_csvs/csvs*/profile2_#{name}.csv")[0]
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

#==== 법안 ====
c2 = 0
puts "-------- 발의법안 처리중 --------"
CSV.foreach(Rails.root+"init_data/politicians_18.csv", :encoding => "UTF-8") do |csv|
  name = csv[4]
  p = Politician.where(:name => name).first #XXX : 동명이인 어떻게 처리
  csv_file_path = Dir.glob("init_data/law_csvs/csvs*/laws_#{name}.csv")[0]
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
    age = 0
    period.keys.each_with_index do |k|
      s,f = period[k]
      (age = k; break) if tmp_date>=s && tmp_date<=f
    end

    next if p.elections.nil? || !p.elections.include?(age)

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

    #XXX : 동명이인 어떻게 처리
    coactors = coactors.map {|name| Politician.where(:name => name).first}.reject {|p| p.nil?}

    b = Bill.new(:title => title,
                 :initiated_at => Date.parse(init_date),
                 :complete => complete,
                 :result => result,
                 :commitee => commitee,
                 :number => number,
                 :code => code,
                 :coactors => coactors,
                 :initiator => p,
                 :summary => summary)
    b.voted_at = Date.parse(complete_date) unless (complete_date.nil? || complete_date.length == 0)
    b.save!
    law_count += 1
  end
  puts "#{law_count}개"
end

#==== 법안에 대한 찬성 반대 ====
#==== 반대는 raw data에 없어서 구현이 안됨
puts "법안에 대한 찬성 반대 입력 중"
puts "=============================\n"

File.open(Rails.root + "init_data/bill_codes.txt", "r").each do |line|
  file_name = line.sub("\n", "") + ".html"

  if File.exists? Rails.root + "raw_data/law_coactors_#{file_name}"
    puts "\n파일명...law_coactors_#{file_name}"

    #raw_data = iconv.iconv(File.new(Rails.root + "raw_data/law_coactors_#{file_name}").read.encode("euc-kr"))
    #detail_raw_data = iconv.iconv(File.new(Rails.root + "raw_data/law_detail_#{file_name}").read.encode("euc-kr")) # coactors에서 법안명을 가져올 수가 없어서 detail 사용
    raw_data = File.open(Rails.root + "raw_data/law_coactors_#{file_name}").read
    detail_raw_data = File.open(Rails.root + "raw_data/law_detail_#{file_name}").read

    doc = Nokogiri::HTML(raw_data)
    detail_doc = Nokogiri::HTML(detail_raw_data)

    agenda = detail_doc.xpath("html/body/table[2]/tbody/tr[2]/td[1]/table[1]/tbody/tr[3]/td[2]/table/tbody/tr[1]/td[1]").inner_text.strip

    bill = Bill.where(title: agenda.to_s).first

    if bill.nil?
      puts "안건...#{agenda}...존재하지않습니다."
    else
      puts "안건...#{bill.title}\n"

      #===찬성 명단
      i = 1
      j = 1
      puts "====== 찬성 명단 ======"
      while !doc.xpath("html/body/table[4]/tr[2]/td[1]/table/tr[2]/td[2]/table/tr[#{j}]/td[1]").inner_text.empty?
        while !doc.xpath("html/body/table[4]/tr[2]/td[1]/table/tr[2]/td[2]/table/tr[#{j}]/td[#{i}]").inner_text.empty?
          agree_member = doc.xpath("html/body/table[4]/tr[2]/td[1]/table/tr[2]/td[2]/table/tr[#{j}]/td[#{i}]").inner_text.to_s
          member = Politician.where(name: agree_member).first
          if !member.nil?
            puts ":..의원...#{member.name}"
            bill.supporters << Politician.where(name: agree_member).first
          end
          i += 1
        end
        i = 1
        j += 1
      end
      if bill.save 
        puts "==== 성공 ====\n"
      else
        puts "==== 실패 ====\n"
      end
    end
  else
    puts "파일명...#{file_name}...존재하지않습니다."
  end
end
