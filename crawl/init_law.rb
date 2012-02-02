#coding:utf-8
require 'net/http'
require 'open-uri'
require 'iconv'
require 'nokogiri'
require 'csv'

iconv = Iconv.new("utf-8", "euc-kr")

unless File.exists? "list.txt"
	puts "`list.txt` must be in #{ARGV[0]}"
	exit 1
end

total_names = File.readlines("list.txt").map {|name| name.gsub /\n/, ''}

processed_names = []
if File.exists? "complete_list.txt"
	processed_names = File.readlines("complete_list.txt").map {|name| name.gsub /\n/,''}
end

names = total_names - processed_names

names.each do |name|
	doc_raw = ""
	begin
		doc_raw = iconv.iconv(Net::HTTP.post_form(URI.parse("http://likms.assembly.go.kr/bill/jsp/BillSearchResult.jsp"), {:PAGE_SIZE=>2000, :PROPOSER=>name.encode("euc-kr"), :PROPOSE_GUBN=>"대표발의".encode("euc-kr"), :AGE_FROM=>1, :AGE_TO=>18}).body)
	rescue
		puts "=====ERR : #{name} search failed====="
		exit 1
	end


	tmp_name = name
	c = 1
	while File.exists? "raw_data/law_list_#{tmp_name}_page1.html"
		tmp_name = name+"_#{c}"
		c+=1
	end
	name = tmp_name

	f = File.open("raw_data/law_list_#{name}_page1.html", "w")
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

	puts "=====#{name} #{init_num}건====="

	#각 의안에 대해..
	CSV.open("laws_#{name}.csv", "w") do |csv|
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
				rescue
					puts "=====ERR : #{code} summary failed ====="
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
					doc3_raw = iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/BillDetail.jsp?bill_id=#{code}").read)
					f = File.open("raw_data/law_detail_#{code}.html", "w")
					f.write doc3_raw
					f.close
				rescue
					puts "=====ERR : #{code} detail failed====="
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
					doc4_raw = iconv.iconv(open("http://likms.assembly.go.kr/bill/jsp/CoactorListPopup.jsp?bill_id=#{code}").read)
					f = File.open("raw_data/law_coactors_#{code}.html", "w")
					f.write doc4_raw
					f.close
				rescue
					puts "=====ERR : #{code} coactors failed====="
				end
			end
			doc4 = Nokogiri::HTML(doc4_raw)
			coactors = doc4.xpath("/html/body/table[2]/tr[2]/td[1]/table/tr[2]/td[2]/table/tr[1]/td").map {|elem| elem.inner_text.to_s}

			csv << [name, init_num, num, code, strip_title, (complete ? "의결" : "계류"), init_date, complete_date, result, summary, coactors.join(","), commitee]
		end #end of each law row
	end #end of CSV

	f = File.open("complete_list.txt", "a")
	f.puts name
	f.close
end
