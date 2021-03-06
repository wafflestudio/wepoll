#encoding: utf-8
require 'csv'

### to do list
# 1. 상임위 중 특별위원회 이름 단축, 상임위 이름 정리
# 2. 법안에 찬성자, 반대자 입력(Rails.root + crawl_bill.rb 참고)
# 3. 발의자가 사람일 경우에 공동 발의자 추가하기(Rails.root + crawl_bill.rb 참고)
###

# 동명이인 처리
=begin
puts "동명이인 처리"
CSV.foreach(Rails.root + "init_data/duplicated.csv", :encoding => "UTF-8") do |csv|
  number = csv[0]
  title = csv[1]
  initiator = csv[2].to_s[0..2]
  coactor = csv[3]
  party = csv[4][0..3]
  p =  Politician.where(name: coactor, party: party).first
  b = Bill.where(number: number).first
  if !b.nil? && !p.nil?
    c = b.coactors.where(name: p.name).first
    if !c.nil? && (c._id != p._id)
      puts "#{number}, present: #{c.name}-#{c.party}, new: #{p.name}-#{p.party}"
      if b.coactors.delete(c).party != c.party
        b.coactors << p
        b.save
      end
    end
  end
end
puts "동명이인 처리 완료"
# 동명이인 처리 완료
=end

=begin
# 지역구 변경
puts "지역구 변경"
Politician.all.each do |p|
  if p.district == "용산구"
    p.district = "용산"
  elsif  p.district == "종로구"
    p.district = "종로"
  elsif  p.district == "금천구"
    p.district = "금천"
  end
  p.party = p.party[0..3]
  p.save
end
puts "지역구 변경 완료"
# 지역구 변경 완료

=begin
# 당명 변경
puts "=== 당명 변경 ==="
Politician.all.each do |p|
  if p.party == "한나라당"
    p.party = "새누리당"
  end
  p.save
end
puts "=== 당명 변경 완료 ==="
# 당명 변경 완료

# 상임위 이름 정리
puts "=== 상임위 이름 정리 ==="
Bill.all.each do |bill|
  case bill.commitee
  when "보건복지위원회"
    bill.commitee = "보건복지"
  when "보건복지가족위원회"
    bill.commitee = "보건복지가족"
  when "외교통상통일위원회"
    bill.commitee = "외교통상"
  when "환경노동위원회" 
    bill.commitee = "환경노동"
  when "교육과학기술위원회"
    bill.commitee = "교육과학"
  when "교육위원회"
    bill.commitee = "교육"
  when "정치개혁특별위원회" || "정치개혁"
    bill.commitee = "정치개혁특별"
  when "농림수산식품위원회"
    bill.commitee = "농림수산"
  when "농림해양수산위원회"
    bill.commitee = "농림해양수산"
  when "행정안전위원회"
    bill.commitee = "행정"
  when "국토해양위원회"
    bill.commitee = "국토해양"
  when "기획재정위원회"
    bill.commitee = "재정"
  when "지식경제위원회"
    bill.commitee = "경제"
  when "재정경제위원회"
    bill.commitee = "재정경제"
  when "국회운영위원회"
    bill.commitee = "국회운영"
  when "법제사법위원회"
    bill.commitee = "사법" 
  when "문화체육관광방송통신위원회"
    bill.commitee = "문화∙미디어"
  when "정무위원회" || "정보" #
    bill.commitee = "정무"
  when "국방위원회"
    bill.commitee = "국방"
  when "정보위원회"
    bill.commitee = "국가정보"
  when "여성가족위원회"
    bill.commitee = "여성가족"
  when "여성위원회"
    bill.commitee = "여성" 
  end
  bill.commitee = "해당 없음" if bill.commitee.nil? || bill.commitee.empty?
  bill.commitee = bill.commitee.sub("위원회","")
  bill.save
end
puts "=== 상임위 이름 정리 완료 ==="
# 상임위 이름 정리 완료
=end

# 19대 출마자 업데이트
puts "=== 19대 출마자 업데이트 ==="
p_list = [];
CSV.foreach(Rails.root + "init_data/center.csv", :encoding => "UTF-8") do |csv|
  name = csv[3]
  party = csv[1].sub(" ","").to_s[0..3]
  district = csv[0]
  birth = csv[6].gsub("/","-")
  job = csv[9]
  education = csv[10]
  experiences = csv[11]

  p = Politician.where(name: name, party: party).first
  pp = Politician.where(name: name).first
  if p.nil? # 19대 출마자 중에서 18대에 없는 사람
    p = Politician.new(name: name, # seeds.rb와 비교했을 때, election_count, military, tweet_name 없음
                       party: party,
                       birthday: birth,
                       district: district,
                       job: job,
                       education: education,
                       experiences: experiences,
                       candidate: true
                      )
                      # 사진 등록
                      # image_url => csv[2] ex) 선관위.com/qwertyasdf.jpg
=begin
    begin
      img_src = "#{img}#{i}.jpg";
      img_to = "#{dir}/#{titleId}_#{no}_#{i}.jpg"

      img_read = open(img_src).read

      file_download = open(img_to, "wb")
      file_download.write(img_read)
      file_download.close
      printf "\r#{msg} 성공: {img_src}"
      i += 1
    rescue
      #printf "#{msg} 실패: #{img_src}\n"
      break 
    end 
=end
   # p.save
    if !pp.nil?
      if name == "강승규"
        puts "@ #{name}(#{pp.party} -> #{party})"
        p.save
      elsif name == "서영신"
        puts "@ #{name}(#{pp.party} -> #{party})"
        pp.party = party
        pp.district = district
        pp.birthday = birth
        pp.job = job
        pp.education = education
        pp.experiences = experiences
        pp.candidate = true
        pp.save
  #      p_list << pp.id
      else
        puts "! #{name}(#{pp.party} -> #{party})"
        pp.party = party
        pp.district = district
        pp.candidate = true
        pp.save
        p_list << pp.id
      end
    else
      puts "#{name}(#{party})"
      p.save
  #    p_list << p.id
    end
  else # 18대 출신인 19대 출마
    # 지역구, 당, 생일, 직업, 학력, 직위(?) 업데이트
    p.party = party
    p.district = district
    p.birthday = birth
    p.job = job
    p.education = education
    p.experiences = experiences
    p.candidate = true
    p.save
  end
end

p_list.each do |p_id|
  p = Politician.find(p_id)
  if !p.nil?
  	puts "crawl_initiated_bills 시작"
    p.crawl_initiated_bills
  	puts "crawl_initiated_bills 끝"
  end
end

Politician.where(canidate: true).each do |p|
  p.elections.each do |age|
    p.calculate_joint_initiate age
  end
end

=begin
CSV.foreach(Rails.root + "init_data/politicians_18.csv", :encoding => "UTF-8") do |csv|
 name = csv[4]
 party = csv[5]
 seoul = csv[2]
 if seoul == "서울"
   p = Politician.where(name: name, party: party).first
   if p.nil?
     puts "==== 존재하지 않음 ==== #{name}(#{party})"
   else
     puts "==== 후보아님 ==== #{name}(#{party})" if !p.candidate
     p.district = ""
     p.save
   end
 elsif seoul.nil?
   p = Politician.where(name: name, party: party).first
   if !p.nil? && !p.candidate
     puts "==== 18후보아님 ==== #{name}(#{party})" if !p.candidate
     p.district = ""
     p.save
   end
 end
end
=end

=begin
puts "=== 19대 출마자 업데이트 완료 ==="
# 19대 출마자 업데이트 완료

# 출석률 계산
Politician.calculate_attendance
# 출석률 계산 완료

# 공동발의 일치도 계산
Politician.calculate_joint_initiate
# 공동발의 일치도 완료
=end
