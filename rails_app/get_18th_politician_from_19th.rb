#encoding: utf-8
require 'csv'

CSV.foreach(Rails.root+"init_data/center_tmp.csv") do |line|
  party = line[1]
  name = line[3]

  p = Politician.where(name: name, party: party).first 

  if !p.nil?
  #printf "#{name}(#{party}) "
  else
  printf "#{name}(#{party}) "
  end
end
