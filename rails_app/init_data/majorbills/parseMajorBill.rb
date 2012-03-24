#coding : utf-8
require 'csv' 
require 'json'


i = 0
names = []
arrOfArr = []
CSV.foreach("MajorBill.csv",:encoding => "UTF-8" ) do |row|
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


def parseMembers(rawstr, debug=false)
  #puts rawstr
  return if rawstr.nil?
  party_rows = rawstr.split("\n")
  puts party_rows if debug
 
  result = {}

  party_rows.each do |row|
    parts = row.split(":")
    next if parts.length <= 1
    party = parts[0].strip
    puts party if debug
    politicians = parts[1].split(/[0-9]+명/)[-1].split(/[() ]/).delete_if do |x| x == "" end 
    puts politicians.to_s if debug
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
  debug = false
  if table["의안 번호"][i].strip == "1803016"
    puts "1803016"
    debug = true
  end
  bills[table["의안 번호"][i].strip] = 	
  {:issue => table["이슈"][i],
   :favored => parseMembers(table["찬성"][i]),
   :opposed => parseMembers(table["반대"][i]),
   :resigned => parseMembers(table["기권"][i]),
   :didntvote => parseMembers(table["표결에 불참"][i]),
   :ontrip => parseMembers(table["출장"][i]),
   :recess => parseMembers(table["휴가"][i]),
   :absent => parseMembers(table["결석"][i],debug)
  }
end



def process_samename_politicians!(party, names)
  if names.include? "김선동"
    dup_pol = Politician.where(:name => "김선동")
    if ["새누리당","한나라당"].include? party
      dup_pol = dup_pol.where(:party => "새누리당")
    else
      dup_pol = dup_pol.where(:party => "진보신당")
    end
    names.delete "김선동"
  elsif names.include? "이영애"
    dup_pol = Politician.where(:name => "이영애")
    if ["새누리당","한나라당"].include? party
      dup_pol = dup_pol.where(:party => "새누리당")
    else
      dup_pol = dup_pol.where(:party => "자유선진")
    end
    names.delete "이영애"
  end
  dup_pol
end



# do none-duplcates first
bills.each do |number,bill|
  b = Bill.where(:number => number).first
  if b.nil?
  	puts "counld'nt find bill number #{number}"
  	next
  end
  b.supporters = []
  b.dissenters = []
  b.attendees = []
  b.absentees = []
  b.issue = bill[:issue]
  b.save

  if bill[:favored]
    bill[:favored].each do |party,names|
      samename_pols = process_samename_politicians! party, names 
      b.supporters << samename_pols
      politicians = Politician.where(:name.in => names)
      b.supporters << politicians
    end
  end

  if bill[:opposed]
    bill[:opposed].each do |party,names|
      samename_pols = process_samename_politicians! party, names 
      b.dissenters << samename_pols
      politicians = Politician.where(:name.in => names)
      b.dissenters << politicians
    end
  end

  if bill[:resigned]
    bill[:resigned].each do |party,names|
      samename_pols = process_samename_politicians! party, names 
      b.attendees << samename_pols
      politicians = Politician.where(:name.in => names)
      b.attendees << politicians
    end
  end

  if bill[:didntvote]
    bill[:didntvote].each do |party,names|
      samename_pols = process_samename_politicians! party, names 
      b.attendees << samename_pols
      politicians = Politician.where(:name.in => names)
      b.attendees << politicians
    end
  end

  if bill[:ontrip]
    bill[:ontrip].each do |party,names|
      samename_pols = process_samename_politicians! party, names 
      b.absentees << samename_pols
      politicians = Politician.where(:name.in => names)
      b.absentees << politicians
    end
  end


  if bill[:absent]
    bill[:absent].each do |party,names|
      samename_pols = process_samename_politicians! party,names 
      b.absentees << samename_pols
      politicians = Politician.where(:name.in => names)
      b.absentees << politicians
    end
  end

  if bill[:recess]
    bill[:recess].each do |party,names|
      samename_pols = process_samename_politicians! party,names 
      b.absentees << samename_pols
      politicians = Politician.where(:name.in => names)
      b.absentees << politicians
    end
  end
 
  next if !b.complete
  num = 0
  supporters = b.supporters ? b.supporters.length : 0
  dissenters = b.dissenters ? b.dissenters.length : 0
  attendees = b.attendees ? b.attendees.length : 0
  absentees = b.absentees ? b.absentees.length : 0
  
  puts "#{b.number}: total #{supporters+dissenters+attendees+absentees} (#{supporters},#{dissenters},#{attendees},#{absentees})"
end

