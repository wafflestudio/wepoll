require 'csv'
f = File.open(Rails.root+"app/assets/javascripts/search.js", "w")
f.write "var search_source=["
Politician.all.each do |member|
  # [ 
  # {"data":"xxxxxx", "sub_data":"xxxxxxxxxx", "label":"xxxxxxxxxxxxx"},
  # ...
  # {"data":"xxxxxx", "sub_data":"xxxxxxxxxx", "label":"xxxxxxxxxxxxx"}
  # ] 
  next if member.candidate == false
  next if member.party == "정부"
  s = "{'form':'#{member.name}','query':'#{member._id.to_s}','type':'1','label':'#{member.name}(#{member.party})'},"
  f.write s
end
CSV.foreach(Rails.root + "init_data/district.csv", :encoding => "UTF-8") do |csv|
  # district
  district = csv[0]
  s = "{'form':'#{district}','query':'#{district}','type':'0','label':'#{district}'},"
  f.write s
  # dong
  tmp_arr = csv[3].split(" ")
  tmp_arr.each_with_index do |dong, i|
    f.write "{'form':'#{dong}','query':'#{district}','type':'2','label':'#{dong}(#{district})'},"
  end 
end
f.seek f.pos-1
f.write "];" 
f.close
