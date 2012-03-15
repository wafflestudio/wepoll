#encoding: utf-8
require Rails.root + 'romanize.rb'
require 'csv'

CSV.foreach(Rails.root+"init_data/politicians_18.csv", :encoding => "UTF-8") do |csv|
name = csv[4]

name_romanize = name.romanize
profile_photo_path = Dir.glob(Rails.root+"init_data/profile_photos/*.jpg").select {|p| p.include? name_romanize}[0]

count = Politician.where(name: name).count
puts "#{name} 동명이인 #{count}명" if count > 1

p = Politician.where(name: name).first
if !p.nil?
	p.profile_photo = File.open(Rails.root + profile_photo_path) unless profile_photo_path.nil?
	if profile_photo_path.nil?
		puts "#{name} photo doesn't exist"  
		p.profile_photo.clear
		if p.save
		puts "clear 성공"
		else 
		puts "#{name} clear 실패"
		end
	else
		if !p.save
		puts "#{name} 사진 등록 실패"
		else
		puts "#{name} 사진 등록 성공"
		end
	end
else
puts "#{name} 디비에 없음"
end
end
