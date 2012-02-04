#coding:utf-8
require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'csv'

total_names = (File.readlines "list.txt").map {|name| name.gsub /\n/, ''}
processed_names = []

if File.exists? "profile_complete_list.txt"
	processed_names = (File.readlines "profile_complete_list.txt").map {|name| name.gsub /\n/,''}
end

names = total_names - processed_names

names.each do |name|
	CSV.open("profile2_#{name}.csv","w") do |csv|
	res = Net::HTTP.post_form(URI.parse("http://watch.peoplepower21.org/New/search.php"), {:mname => name})
	tmp = res.body.match /URL=\.(\/cm_info\.php\?member_seq=(\d+))/

	people = [name]
	party = ""

	if tmp.nil?
#		doc = Nokogiri::HTML(res.body.strip)
#		r = doc.xpath("/html/body/center/table/tr[4]/td/table/tr/td[3]/table[5]//a")
#		if r.length == 0
			puts "=====ERR : Not found #{name}=====" 
			next
#		else
#			r.each do |row|
#				party = row.attr('title').split('-')[0] #당명
#			end
#		end
	end

	url = tmp[1]
	num = tmp[2]

	doc1_raw = ""
	if File.exists? "profile_raw_data/#{name}_#{num}.html"
		doc1_raw = File.read "profile_raw_data/#{name}_#{num}.html"
	else
		sleep(1)
		doc1_raw = open("http://watch.peoplepower21.org/New/#{url}").read
		f = File.open("profile_raw_data/#{name}_#{num}.html","w")
		f.write doc1_raw
		f.close
	end
	doc = Nokogiri::HTML(doc1_raw)
	profile_img = (doc.xpath "/html/body/center/table/tr[4]/td/table/tr/td[3]/table[2]/tr[1]/td/table/tr[2]/td[1]/a/img").attr("src").to_s
	f = File.open("profile_raw_data/#{name}_#{profile_img.split("/").last}", "w")
	sleep(1)
	f.write open("http://watch.peoplepower21.org#{profile_img}").read #이미지
	f.close

	info_table = doc.xpath("/html/body/center/table/tr[4]/td/table/tr/td[3]/table[2]/tr[1]/td/table/tr[2]/td[3]/table")
	#name = info_table.xpath("tr[1]/td/table/tr/td/span[1]").inner_text
	name_hanja = info_table.xpath("tr[1]/td/table/tr/td/span[2]").inner_text.match(/\((.*)\)/)[1]
	current_status = info_table.xpath("tr[2]/td").inner_text

	commitee = ""
	contact = ""
	email = ""
	url = ""
	position = ""

	2.upto(info_table.xpath("tr").size) do |i|
		k = info_table.xpath("tr[#{i}]/td[1]").inner_text.strip
		v = info_table.xpath("tr[#{i}]/td[2]").inner_text.strip

		case k
		when "상임위"
			commitee = v
		when "연락처"
			contact = v
		when "이메일"
			email = v
		when "홈페이지"
			url = v
		when "당직"
			position = v
		end
	end

	doc2_raw = ""
	if File.exists? "profile_raw_data/#{name}_#{num}_abstract.html"
		doc2_raw = File.read "profile_raw_data/#{name}_#{num}_abstract.html"
	else
		sleep(1)
		doc2_raw = open("http://watch.peoplepower21.org/New/cm_info_act_abstract.php?member_seq=#{num}").read
		f = File.open "profile_raw_data/#{name}_#{num}_abstract.html", "w"
		f.write doc2_raw
		f.close
	end
	doc = Nokogiri::HTML(doc2_raw)
	
	#본회의 출석
	meeting_rows = doc.xpath("/html/body/table[2]/tr[2]/td/a").children.select {|cn| cn.text?}.map {|r| r.inner_text.strip}

	#상임위 출석
	commitee_rows = doc.xpath("/html/body/table[5]/tr[2]/td").children.select {|cn| cn.text?}.map {|r| r.inner_text.strip}

	#특이사항
	doc3_raw = ""
	if File.exists? "profile_raw_data/#{name}_#{num}_special.html"
		doc3_raw = File.read "profile_raw_data/#{name}_#{num}_special.html"
	else
		sleep 1
		doc3_raw = open("http://watch.peoplepower21.org/New/cm_info_act_abstract.php?member_seq=#{num}").read
		f = File.open "profile_raw_data/#{name}_#{num}_special.html", "w"
		f.write doc3_raw
		f.close
	end
	doc = Nokogiri::HTML(doc3_raw)

	morals = []
	1.upto doc.xpath("/html/body/table[2]/tr").length do |i|
		tr = doc.xpath("/html/body/table[2]/tr[#{i}]")
		morals = doc.xpath("/html/body/table[2]/tr[#{i+1}]/td").children.select {|cn| cn.text?} if tr.inner_text.strip == "윤리특위"
	end

	csv << [name, name_hanja, profile_img, current_status, commitee, contact, email, url, position, meeting_rows.join("\n"), commitee_rows.join("\n"), morals.join("\n")]
	end #end of csv

	f = File.open("profile_complete_list.txt", "a")
	f.puts name
	f.close
end #end of each name
