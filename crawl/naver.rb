#coding:utf-8
require 'net/http'
require 'open-uri'
require 'iconv'
require 'nokogiri'
require 'csv'


unless File.exists? "list.txt"
	puts "`list.txt` must be in #{ARGV[0]}"
	exit 1
end

total_names = File.readlines("list.txt").map {|name| name.gsub /\n/, ''}

processed_names = []
if File.exists? "naver_complete_list.txt"
	processed_names = File.readlines("naver_complete_list.txt").map {|name| name.gsub /\n/,''}
end

names = total_names - processed_names

names.each do |name|
	doc_raw = ""
	begin
		doc_raw = Net::HTTP.get(URI.parse("http://people.search.naver.com/search.naver?sm=sbx_hty&where=people&ie=utf8&query="+URI.escape(name)+"&x=0&y=0"))
	rescue
		puts "=====ERR : #{name} search failed====="
		exit 1
	end


	tmp_name = name
	c = 1
	while File.exists? "raw_data/naver_#{tmp_name}_page1.html"
		tmp_name = name+"_#{c}"
		c+=1
	end
	name = tmp_name

	f = File.open("raw_data/naver_#{name}_page1.html", "w")
	f.write doc_raw
	f.close

	doc = Nokogiri::HTML(doc_raw)


	#프로필 정보
	row = doc.css("dl.detail_profile")


	#출생, 소속1, 소속2, 소속3, 학력, 수상, 경력, 사이트, 가족, 
	#각 프로필 정보에 대해
	CSV.open("result/naver_#{name}.csv", "w") do |csv|
		#initialize
		birth=""
		belong=[]
		belong[0]=""
		belong[1]=""
		belong[2]=""
		edu=""
		award=""
		career=""
		site=""
		family=""

		#출생
		birth = row.css('dt[text()=출생]').first.next.text unless row.css('dt[text()=출생]').first.nil?
		#소속
		if(belongs = row.css('dt[text()=소속]').first)
			for i in 0..belongs.next.next.text.split(',').count-1
				belong[i] = belongs.next.next.text.split(',')[i].strip
			end
		end
		#학력
		edu = row.css('dt[text()=학력]').first.next.next.text unless row.css('dt[text()=학력]').first.nil?
		#수상
		award = row.css('dt[text()=수상]').first.next.next.text unless row.css('dt[text()=수상]').first.nil?
		#경력
		career = row.css('dt[text()=경력]').first.next.next.text unless row.css('dt[text()=경력]').first.nil?
		#사이트
		site = row.css('dt[text()=사이트]').first.next.next.text unless row.css('dt[text()=사이트]').first.nil?
		#가족
		family = row.css('dt[text()=가족]').first.next.next.text unless row.css('dt[text()=가족]').first.nil?

		csv << [birth, belong[1], belong[2], belong[3], edu, award, career, site, family]
	end #end of CSV

	f = File.open("naver_complete_list.txt", "a")
	f.puts name
	f.close
end
