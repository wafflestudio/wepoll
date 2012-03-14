#encoding:utf-8
require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'csv'

first_page = 98
last_page = 155 # http://watch.peoplepower21.org/New/monitor_voteresult.php?page=#{page}의 마지막 페이지

first_page.upto(last_page) do |page|
  begin # 열려라 국회에서 본회의표결 리스트 뽑기
    page_raw = Net::HTTP.get(URI.parse("http://watch.peoplepower21.org/New/monitor_voteresult.php?page=#{page}"))
    puts "### #{page}번째 페이지 시작 ###"
  rescue
    puts "=== ERROR : #{page}번째 페이지 검색 실패 ==="
    exit 1
  end

  page_doc = Nokogiri::HTML(page_raw)
  2.upto(17) do |i| 
    page_path = page_doc.xpath("html/body/center/table/tr[4]/td/table/tr/td[3]/table[4]/tr/td/table/tr[#{i}]/td[3]") # start from index 2
    break if page_path.empty? # 페이지의 마지막 법안

    if page_path.xpath("a").nil?
      puts "=== ERROR : #{page} - #{i} 페이지 검색 실패 ==="
      next
    end
    url = page_path.xpath("a").attr("href").to_s

    begin # 본회의 표결 리스트 중에서 하나를 자세히 보기
      sub_page_raw = Net::HTTP.get(URI.parse(url)) # ex) http://watch.peoplepower21.org/New/c_monitor_voteresult_detail.php?mbill=6687 
    rescue
      puts "=== ERROR : #{url} 본회의 페이지 검색 실패 ==="
      exit 1
    end

    sub_page_doc = Nokogiri::HTML(sub_page_raw)
    begin 
      sub_url = sub_page_doc.xpath("html/body/center/table/tr/td/table/tr/td[2]/table[3]/tr/td/table/tr/td/table[1]/tr[1]/td/a").attr("href").to_s
      title_data = sub_page_doc.xpath("html/body/center/table/tr/td/table/tr/td[2]/table[3]/tr/td/table/tr/td/table[1]/tr[1]/td/b").inner_text.to_s
    rescue
      puts "=== ERROR : #{page} - #{i} 페이지 검색 실패 ==="
      next
    end

    # ex) http://likms.assembly.go.kr/bill/jsp/BillDetail.jsp?bill_id=PRC_Y1W2J0X2E1B4T0L9K4O2T3O2O8S8H1
    #     => called main_page

    begin # 국회 의안정보시스템으로 자세히 보기 
      main_page_raw = Net::HTTP.get(URI.parse(sub_url))
    rescue
      puts "=== ERROR : #{sub_url} 의안정보 페이지 검색 실패 ==="
      exit 1
    end

    main_page_doc = Nokogiri::HTML(main_page_raw)
    main_page_path = main_page_doc.xpath("html/body/table[2]/tbody/tr[2]/td/table/tbody/tr[4]/td[2]/table/tbody")
    # ("tr[2]/td[2]/table/tbody/tr[2]/td[i]/div").inner_text.to_s # from 1 / 의안번호, 제안일자, 제안자
    # ("tr[6]/td[2]/table[j]/tbody/tr[2]/td[i]/div").inner_text.to_s
    # ("tr[10]/td[2]/table/tbody/tr[2]/td[i]/div").inner_text.to_s

    title = title_data.strip
    initiated_at = main_page_path.xpath("tr[2]/td[2]/table/tbody/tr[2]/td[2]/div").inner_text.to_s
    voted_at = main_page_path.xpath("tr[10]/td[2]/table/tbody/tr[2]/td[2]/div").inner_text.to_s[0..9]
    result = main_page_path.xpath("tr[10]/td[2]/table/tbody/tr[2]/td[4]/div").inner_text.to_s
    number = main_page_path.xpath("tr[2]/td[2]/table/tbody/tr[2]/td[1]/div").inner_text.to_s
    initiator_name = main_page_path.xpath("tr[2]/td[2]/table/tbody/tr[2]/td[3]/div").inner_text.strip
    initiator_img = main_page_path.xpath("tr[2]/td[2]/table/tbody/tr[2]/td[3]/div/img")

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
    end
    commitee = main_page_path.xpath("tr[6]/td[2]/table[1]/tbody/tr[2]/td[1]/div").inner_text.to_s
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
    when "기획재정위원회"
      commitee = "재정"
    end
    code = sub_url[60..100]
    summary = "''"
    if !initiator_img.empty?
      initiator_name = initiator_name.strip[0..2]
    end
    p = Politician.where(name: initiator_name).first
    if p.nil?
      p = Politician.new(name: initiator_name,
                         party: "정부",
                         election_count: 0,
                         birthday: Time.now,
                         district: "서울") 
      p.save
    end

    coactor_names = []
    supporter_names = []
    dissenter_names = []

    sub_page_row = sub_page_doc.xpath("html/body/center/table/tr/td/table/tr/td[2]/table[3]/tr/td/table/tr/td/table")

    #puts "===TITLE: #{title}"
    2.upto(8).each do |i|
      opinion = sub_page_row.xpath("tr[#{i}]/td[1]").children[0].to_s.strip
      break if opinion.empty?
      if opinion == "찬성" || opinion == "반대"
        #printf "=====#{opinion}:"
        cnt = sub_page_row.xpath("tr[#{i}]/td[1]").children[2].to_s.strip.sub("(", "").sub("명)", "").to_i 

        k = 2
        while(true)
          sub_cnt = sub_page_row.xpath("tr[#{i}]/td[2]").children[k].to_s.strip.sub(": ","").sub(" (","").to_i
          party = sub_page_row.xpath("tr[#{i}]/td[2]").children[k-1].inner_text.to_s
          party = "새누리당" if party == "한나라당"
          1.upto(sub_cnt) do |l|
            name = sub_page_row.xpath("tr[#{i}]/td[2]").children[k+2*l-1].inner_text.to_s
            #printf " #{name}(#{party})"
            po = Politician.where(name: name, party: party).first
            supporter_names << po if !p.nil? && opinion == "찬성"
            dissenter_names << po if !p.nil? && opinion == "반대"
          end
          k += 2 * sub_cnt + 3
          break if sub_page_row.xpath("tr[#{i}]/td[2]").children[k-1].nil?
        end
      end
    end #end of opinion

    if title.empty?
      puts "### ERROR"
    else
      #puts title + "," + initiated_at +","+voted_at+","+result+","+commitee+","+code+","+number+","+initiator_name
      b = Bill.where(number: number).first
      if b.nil?
        b = Bill.new(title: title, initiated_at: initiated_at, voted_at: voted_at, complete: true, result: result, commitee: commitee, code: code, number: number, summary: summary)
        b.initiator = p
        b.coactors = coactor_names
        b.supporters = supporter_names
        b.dissenters = dissenter_names
        puts " #=== 성공 ===# #{p.name} #{supporter_names.count}" if b.save
      else
        b.initiator = p
        b.coactors = coactor_names
        b.supporters = supporter_names
        b.dissenters = dissenter_names
        puts " #======== 존재 ===# #{title} #{supporter_names.count}" if b.save
      end
    end
  end
end
