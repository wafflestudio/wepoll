#encoding: utf-8
require 'net/http'
require 'open-uri'
require 'iconv'
require 'nokogiri'
require 'csv'

html = Net::HTTP.get(URI.parse("http://info.nec.go.kr/electioninfo/electionInfo_report.xhtml?electionId=0020120411&requestURI=%2Felectioninfo%2F0020120411%2Fpc%2Fpcri03_ex.jsp&topMenuId=PC&secondMenuId=PCRI03&menuId=PCRI03&statementId=PCRI03_%232&electionCode=2&cityCode=1100&townCode=-1&sggCityCode=-1&sggTownCode=-1&x=20&y=12"))

doc = Nokogiri::HTML(html)

doc_path = doc.xpath("html/body/div/div[2]/div/div[2]/div[4]/div[4]/table/tbody")

# 선거구 / 소속 정당명 / 사진 / 성명(한자) / 성별 / 생년월일(연령) / 주소 / 직업 / 학력 / 경력 / 등록일자
# district / party / picture / name(chinese) / gender / birth / address / job / academic / career / register

i = 0

puts "start=================="
CSV.open("center.csv", "w") do |csv|
  while true
    row = doc_path.children[i]
    break if row.nil?
    district = row.children[0].inner_text.to_s.strip
    if district && (%w(구 시).include? district[-2]) && (%w(갑 을 병 정 무 기 경 신 임 계).include? district[-1])
      if district.length-2 >= 2
        district = district[0...-2]+district[-1]
      end
    end
    party = row.children[2].inner_text.to_s.strip
    picture = "http://info.nec.go.kr"+row.children[4].xpath("img").attr("src").to_s
    name = row.children[6].children[0].inner_text.to_s
    chinese = row.children[6].children[2].inner_text.to_s.sub("(","").sub(")","")
    gender = row.children[8].inner_text.to_s.strip
    birth = row.children[10].children[0].to_s
    age = row.children[10].children[2].to_s.sub("(","").sub(")","")
    address = row.children[12].inner_text.to_s
    job = row.children[14].inner_text.to_s.strip
    academic = row.children[16].inner_text.to_s.strip
    temp_career = Array.new
    0.upto(2)  do |i|
      temp_row = row.children[18].children[i * 2].to_s 
      temp_career << temp_row if !temp_row.empty? 
    end
    career = temp_career.join(",")
    register  = row.children[20].inner_text.to_s
    str = district+","+party+","+picture+","+name+","+chinese+","+gender+","+birth+","+age+","+address+","+job+","+academic+","+career+","+register
    puts str
    csv << [district,party,picture,name,chinese,gender,birth,age,address,job,academic,career,register]
    i += 1
  end
end
puts "end===================="
