#encoding: utf-8
require 'csv'

puts "통합진보당 김선동 1813105 1812939"
puts "새누리당 이영애 0건" 

f = File.open(Rails.root+"duplicated_bill_dump", "w")
duplicated_members = ["csvs/laws_gimseondong.csv", "csvs3/laws_iyeongae.csv"]

duplicated_members.each_with_index do |path, i|
  CSV.foreach(Rails.root+"init_data/law_csvs/#{path}", :encoding => "UTF-8") do |line|
    initiator_name = line[0]
    number = line[2]
    code = line[3]
    title = line[4]
    complete = line[5]
    initiated_at = line[6]
    voted_at = line[7]
    result = line[8] 
    summary = line[9].empty? ? "''" : "! \"" + line[9] + "\""
    coactor_names = line[10].split(",")
    commitee = line[11]

    puts "#{initiator_name} #{number} #{code} #{title} #{coactor_names.join(',')}"

    if i == 0
      p = Politician.where(name: initiator_name).first # 한나라당 김선동
    elsif i == 1
      p = Politician.where(name: initiator_name).last # 자유선진당 이영애
    end
    if !p.nil?
      f.write "!averyspecialandlongstringwhichwouldnotbeappearedinthistextfilekk!---\n"
      f.write ":title: #{title}\n"
      f.write ":initiated_at: #{initiated_at}\n"
      f.write ":voted_at: #{voted_at}\n"
      if result.empty?
        f.write ":complete: false\n"
      else
        f.write ":complete: true\n"
      end
      if result.empty?
        f.write ":result: ''\n" 
      else
        case result
        when "가결"
          result = "approved"
        when "부결"
          result = "rejected"
        when "폐기" || "대안폐기"
          result = "disposal"
        when "철회" 
          result = "withdraw"
        when "임기만료 폐기"
          result = "expired"
        else
          result = "error"
        end
        f.write ":result: #{result}\n"
      end
      case commitee
      when "보건복지위원회"
        commitee = "보건복지"
      when "외교통상통일위원회"
        commitee = "외교통상"
      when "환경노동위원회" 
        commitee = "환경노동"
      when "교육과학기술위원회"
        commitee = "교육과학"
      when "정치개혁특별위원회"
        commitee = "정치개혁"
      when "행정안전위원회"
        commitee = "행정"
      when "국토해양위원회"
        commitee = "국토해양"
      end
      f.write ":commitee: #{commitee}\n"
      f.write ":code: #{code}\n"
      f.write ":number: #{number}\n"
      f.write ":summary: #{summary}\n"
      f.write ":initiator_name: #{p.party} #{p.name}\n"
      f.write ":coactor_namess:\n"
      coactor_names.each do |coactor|
        p = Politician.where(name: coactor).first
        f.write "- #{p.party} #{p.name}\n" if !p.nil?
      end
      f.write ":supporter_names: []\n"
      f.write ":dissenter_names: []\n"
    else
      puts "###error #{initiactor_name}\n"
    end
  end
end
f.close
