#encoding: utf-8
require 'csv'

i = 0
list = []
CSV.foreach(Rails.root+"init_data/center.csv", :encoding => "UTF-8") do |line|
  i += 1
  party = line[1]
  name = line[3]
  district = line[0]
  
  party = party[0..3]
  
=begin
  if party != "무소속" && party != "새누리당" && party != "민주통합당" && party != "통합진보당" && party != "자유선진" && party != "국민생각당"
    printf name + "(" + party + ", " + district + ") "
  end
=end
  list += ["#{name}_#{party}"]
  p = Politician.where(name: name, party: party)
#  p.first.candidate = true
#  p.first.save

  puts "#{i} #{name}(#{party})" if p.count == 1
=begin
  if !p.nil?
    puts "#{p} - #{p.name}(#{p.party})"
    p.candidate = true
    if p.save
      i += 1
      puts i
    end
  else
    printf "#{name}(#{party}) "
  end
=end
end
#puts list.uniq.count

=begin
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
end
=end
