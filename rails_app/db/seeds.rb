#coding : utf-8
require 'csv'
require 'mongoid'

CSV.foreach(Rails.root+"init_data/politicians_18.csv") do |csv|
  district = csv[3]
  name = csv[4]
  party = csv[5]
  count = 0
  count = (c=csv[7][0]; c=='초' ? 1 : c=='재' ? 2 : c.to_i) unless csv[7].nil?
  birth = Date.parse("19"+csv[8]) unless csv[8].nil?

  military = nil
  if csv[9] == '군필'
    complete_class = csv[10]
    military = "#{complete_class[0...2]} #{complete_class[2..-1]} #{csv[12]}"
  elsif csv[9] == '면제'
    military = "면제#{csv[12]}"
  end

  profile_photo_path = Dir.glob("init_data/profile_photos/#{name}*.jpg")[0]

  p = Politician.new(:name => name,
                     :party => party,
                     :election_count => count,
                     :birthday => birth,
                     :military => military,
                     :district => district)
  p.profile_photo = File.open(Rails.root + profile_photo_path) unless profile_photo_path.nil?

  p.save!
end
