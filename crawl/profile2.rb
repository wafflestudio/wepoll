require 'open-uri'
require 'nokogiri'
require 'net/http'

total_names = (File.readlines "list.txt").map {|name| name.gsub /\n/, ''}
complete_names = (File.readlines "profile_complete_list.txt").map {|name| name.gsub /\n/,''}

names = total_names - complete_names

names.each do |name|
	res = Net::HTTP.post_form(URI.parse("http://watch.peoplepower21.org/New/search.php"), {:mname => name})
	tmp = res.body.match /URL=\.(\/cm_info\.php\?member_seq=(\d+))/

	(puts "=====ERR : Not found #{name}=====" ;next) if tmp.nil?

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
	profile_img = (doc.xpath "/html/body/center/table/tr[4]/td/table/tr/td[3]/table[2]/tr[1]/td/table/tr[2]/td[1]/a/img").attr("src")
	f = File.open("profile_raw_data/#{name}_#{profile_img.split("/").last}", "w")
	f.write open("http://watch.peoplepower21.org#{profile_img}").read
	f.close

	info_table = doc.xpath("/html/body/center/table/tr[4]/td/table/tr/td[3]/table[2]/tr[1]/td/table/tr[2]/td[3]/table")
	#name = info_table.xpath("tr[1]/td/table/tr/td/span[1]").inner_text
	name_hanja = info_table.xpath("tr[1]/td/table/tr/td/span[2]").inner_text.match(/\((.*)\)/)[1]
	current_status = info_table.xpath("tr[2]/td").inner_text

	2.upto(info_table.xpath("tr").size) do |i|
		k = info_table.xpath("tr[#{i}]/td[1]").inner_text
		v = info_table.xpath("tr[#{i}]/td[2]").inner_text
	end
end
