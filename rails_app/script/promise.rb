require 'csv'

number = 0
name = ""
party = ""
promises = []
detail_promises = []
distrit = ""

flag = 0
count = 0
detail = 0

cnt = 1

CSV.foreach(Rails.root + "init_data/promise.csv", :encoding => "UTF-8") do |csv|
  flag = csv[0]
  if flag == "----"
  	party = party.sub(" ", "")
  	p = Politician.where(name: name, party: party[0..3]).first
    if p.nil?
      puts "ERROR1 #{name}(#{number}, #{party})"
    else
      promises.each_with_index do |title, i|
        pl = Pledge.new(title: title, content: detail_promises[i])
        pl.politician = p
        if !pl.save
          puts "ERROR3 #{name} #{title} #{detail_promises[i]}"
        end
      end
      p.number = number
      if p.save
      	puts "#{cnt} - " + p.promises.join(", ")
      else
        puts "ERRROR2 #{name}(#{number}, #{party})"
      end
    end
    cnt += 1
  	count = 0
  	promises = []
  	detail_promises = []
  	next
  end

  if count  == 0
  	district = csv[0]
  	count += 1
  elsif count == 1
    name = csv[0]
    number = csv[1]
    count += 1
  elsif count == 2
    party = csv[0]
    count += 1
  elsif count == 3
    if detail == 0
      promises << csv.join("")[4..csv.join("").length]
      detail = 1
    else
      detail_promises << csv.join("")
      detail = 0
    end
  end
end
