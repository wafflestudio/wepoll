#encoding: utf-8
require 'csv'

CSV.foreach(Rails.root+"init_data/center.csv", :encoding => "UTF-8") do |line|
  party = line[1]
  name = line[3]
  district = line[0]
  
  if party != "무소속" && party != "새누리당" && party != "민주통합당" && party != "통합진보당" && party != "자유선진" && party != "국민생각당"
    printf name + "(" + party + ", " + district + ") "
  end
=begin
  p = Politician.where(name: name, party: party).first 

  if !p.nil?
    #printf "#{name}(#{party}) "
    p.candidate = true
    p.save
  else
    #printf "#{name}(#{party}) "
  end
=end
end

CSV.foreach(Rails.root+"init_data/center_busan.csv", :encoding => "UTF-8") do |line|
  party = line[1]
  name = line[3]
  district = line[0]
  
  if party != "무소속" && party != "새누리당" && party != "민주통합당" && party != "통합진보당" && party != "자유선진" && party != "국민생각당"
    printf name + "(" + party + ", " + district + ") "
  end
=begin
  p = Politician.where(name: name, party: party).first 

  if !p.nil?
    #printf "#{name}(#{party}) "
    p.candidate = true
    p.save
  else
    #printf "#{name}(#{party}) "
  end
=end
end
