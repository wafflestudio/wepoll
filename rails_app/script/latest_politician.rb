#encoding: utf-8
require 'csv'

CSV.foreach("./init_data/modify.csv", :encoding => "UTF-8") do |csv|
	district = csv[0]
	name = csv[1]
	party = csv[3]
	party = party[0..3]
	twitter = csv[4]

	count = Politician.where(name: name, party: party).count
	p = Politician.where(name: name, party: party).first	

	if !p.nil?
		if count > 1
			puts "동명이인 #{name}"
		else
		p.tweet_name = twitter
		if p.tweet_name == "없음"
			puts "없다잉 #{p.name}"
			p.tweet_name = nil 
		end
#		p.candidate = true
		puts "실패" if !p.save
		end
	else
		p = Politician.new(name: name, party: party, district: district)
		if p.save
			puts "성공 #{name}(#{party})"
		else
			puts "새로 만들기 실패"
		end
	end
end
