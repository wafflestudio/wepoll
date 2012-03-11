#encoding: utf-8
require 'csv'

### to do list
# 1. 상임위 중 특별위원회 이름 단축, 상임위 이름 정리
# 2. 법안에 찬성자, 반대자 입력(Rails.root + crawl_bill.rb 참고)
# 3. 발의자가 사람일 경우에 공동 발의자 추가하기(Rails.root + crawl_bill.rb 참고)
###

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
=begin
Bill.all.each do |bill|
  case bill.commitee
  when "보건복지위원회"
    bill.commitee = "보건복지"
  when "외교통상통일위원회"
    bill.commitee = "외교통상"
  when "환경노동위원회" 
    bill.commitee = "환경노동"
  when "교육과학기술위원회"
    bill.commitee = "교육과학"
  when "정치개혁특별위원회"
    bill.commitee = "정치개혁"
  when "행정안전위원회"
    bill.commitee = "행정"
  when "국토해양위원회"
    bill.commitee = "국토해양"
  when "기획재정위원회"
    bill.commitee = "재정"
  end
  b.save
end
=end
puts "=== 상임위 이름 정리 완료 ==="
# 상임위 이름 정리 완료

# 19대 출마자 업데이트
puts "=== 19대 출마자 업데이트 ==="
CSV.foreach(Rails.root + "init_data/center.csv") do |csv|
  name = csv[3]
  party = csv[1]
  district = csv[0]
  birth = csv[6].gsub("/","-")
  job = csv[9]
  education = csv[10]
  experiences = csv[11]

  p = Politician.where(name: name, party: party).first
  if p.nil? # 19대 출마자 중에서 18대에 없는 사람
    p = Politician.new(name: name, # seeds.rb와 비교했을 때, election_count, military, tweet_name 없음
                       party: party,
                       birthday: birth,
                       district: district,
                       job: job,
                       education: education,
                       experiences: experiences
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
      printf "\r#{msg} 성공: #{img_src}"
      i += 1
    rescue
      #printf "#{msg} 실패: #{img_src}\n"
      break 
    end 
=end
                      p.save
  else # 18대 출신인 19대 출마
    # 지역구, 당, 생일, 직업, 학력, 직위(?) 업데이트
    p.party = party
    p.district = district
    p.birthday = birth
    p.job = job
    p.education = education
    p.experiences = experiences
    p.save
  end
end
puts "=== 19대 출마자 업데이트 완료 ==="
# 19대 출마자 업데이트 완료

# 출석률 계산
Politician.calculate_attendance
# 출석률 계산 완료

# 공동발의 일치도 계산
Politician.calculate_joint_initiate
# 공동발의 일치도 완료
