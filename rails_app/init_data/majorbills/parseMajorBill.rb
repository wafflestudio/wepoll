#encoding:utf-8
require 'csv' 
require 'json'

i = 0
names = []
arrOfArr = []
CSV.foreach("MajorBill.csv") do |row|
  if i == 0
    names = row
  else
    arrOfArr.push row
  end
  i = i + 1
end

table = {}
numBills = arrOfArr.length

names.each_index do |i|
  table[names[i]] = []
  arrOfArr.each do |arr|
    table[names[i]].push arr[i]
  end
end



def parseMembers(rawstr)
  #puts rawstr
  return if rawstr.nil?
  party_rows = rawstr.split("\n")
 
  result = {}

  party_rows.each do |row|
    parts = row.split(":")
    return if parts.length <= 1
    party = parts[0].strip
    politicians = parts[1].split(/[0-9]+명/)[1].split(/[() ]/).delete_if do |x| x == "" end 
    result[party] = politicians
  end
  result
end

#puts table["제안일"]
#puts table["본회의 처리"]
#puts table["처리일"]
#puts table["처리결과"]
#puts table["의안 번호"]
#puts table["이슈"]
#puts table["법안명"]
#puts table["설명"]
#puts table["발의"]
#puts table["찬성"]
#puts table["반대"]
#puts table["기권"]
#puts table["표결에 불참"]
#puts table["출장"]
#puts table["휴가"]
#puts table["결석"]
bills = {}
for i in 0..(numBills-1) do
  bills[table["의안 번호"][i].strip] = 	
  {:favored => parseMembers(table["찬성"][i]),
   :opposed => parseMembers(table["반대"][i]),
   :resigned => parseMembers(table["기권"][i]),
   :didntvote => parseMembers(table["표결에 불참"][i]),
   :ontrip => parseMembers(table["출장"][i]),
   :recess => parseMembers(table["휴가"][i]),
   :absent => parseMembers(table["결석"][i])
  }
end
puts bills.to_json
