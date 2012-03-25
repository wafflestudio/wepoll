#coding:utf-8
require 'net/http'
require 'open-uri'
require 'iconv'
require 'nokogiri'
require 'csv'

iconv = Iconv.new("utf-8", "euc-kr")

doc_raw = ""
page_size = 8592
age_from = 17
age_to = 17

age_from.upto(age_to) do |age|
  begin
    doc_raw = iconv.iconv(Net::HTTP.post_form(URI.parse("http://likms.assembly.go.kr/bill/jsp/BillSearchResult.jsp"), {:PAGE_SIZE=>page_size, :PROPOSE_GUBN=>"전체".encode("euc-kr"), :AGE_FROM=>age, :AGE_TO=>age}).body)
    system "mkdir bills_#{age}"
  rescue
    puts "=====ERR : #{age} search failed====="
    exit 1
  end

  doc = Nokogiri::HTML(doc_raw)
  title_strip_regex = /(.*)\(.*\)$/
    code_strip_regex = /GoDetail\(\'([a-z_A-Z0-9]+)\'\)/
    elem = doc.xpath("/html/body/table[2]/tbody/tr[2]/td[1]")[0]
  s = elem.children[1].children[0].children[0].children[2].children[3].children[0].to_s.strip

  #각 의안에 대해..
  CSV.open("bills_#{age}.csv", "w") do |csv|
    1.upto(page_size).each do |i|
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
      #처리 플래그 (처리=true, 계류=false)
      complete = row.xpath("td[2]/img").attr("src").to_s.split("/").last == "icon_02.gif"
      #발의일자
      init_date = row.xpath("td[4]").children[0].to_s.strip
      #의결일자
      complete_date = row.xpath("td[5]").children[0].to_s.strip
      #의결결과
      result = row.xpath("td[6]").children[0].to_s.strip

      puts "#{num}\t#{strip_title}\t#{init_date}"

      #의안 써머리
      doc2_raw = ""
      begin
        sleep(1)
        doc2_raw = iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/SummaryPopup.jsp?bill_id=#{code}").read)
        f = File.open("bills_#{age}/law_summary_#{code}.html", "w")
        f.write doc2_raw
        f.close
      rescue
        puts "=====ERR : #{code} summary failed ====="
      end
      doc2 = Nokogiri::HTML(doc2_raw)
      summary = doc2.xpath("/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[2]/span[2]").inner_text.strip

      #위원회
      doc3_raw = ""
      begin
        sleep(1)
        doc3_raw = iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/BillDetail.jsp?bill_id=#{code}").read)
        f = File.open("bills_#{age}/law_detail_#{code}.html", "w")
        f.write doc3_raw
        f.close
      rescue
        puts "=====ERR : #{code} detail failed====="
      end
      doc3 = Nokogiri::HTML(doc3_raw)
      commitee = doc3.xpath("/html/body/table[2]/tbody/tr[2]/td/table/tbody/tr[4]/td[2]/table/tbody/tr[6]/td[2]/table/tbody/tr[2]/td/div").children[0].to_s

      #발의의원
      doc4_raw = ""
      begin
        sleep(1)
        doc4_raw = iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/CoactorListPopup.jsp?bill_id=#{code}").read)
        f = File.open("bills_#{age}/law_coactors_#{code}.html", "w")
        f.write doc4_raw
        f.close
      rescue
        puts "=====ERR : #{code} coactors failed====="
      end
      doc4 = Nokogiri::HTML(doc4_raw)
      coactors = doc4.xpath("/html/body/table[2]/tr[2]/td[1]/table/tr[2]/td[2]/table/tr[1]/td").map {|elem| elem.inner_text.to_s}

      csv << [num, code, strip_title, (complete ? "의결" : "계류"), init_date, complete_date, result, summary, coactors.join(","), commitee]
    end #end of each law row
  end #end of CSV
end
