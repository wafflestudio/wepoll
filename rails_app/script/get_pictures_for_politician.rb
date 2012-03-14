#encoding: utf-8
require 'csv'
require 'net/http'
require 'open-uri'
require './romanize'

#csv_list = ["center.csv", "center_busan.csv"]
csv_list = ["center.csv"]

csv_list.each do |csv_path|
  CSV.foreach(Rails.root + "init_data/" + csv_path, :encoding => "UTF-8") do |csv|
    begin
      name = csv[3]
      party = csv[1]
      img_src = csv[2]

      img_to = "init_data/profile_photos_19/" + party.romanize + "_" + name.romanize + ".jpg"

      if !File.exists?(Rails.root + img_to)
        puts img_to
        puts name + " " + party

        img_read = open(img_src).read

        file_download = open(img_to, "wb")
        file_download.write(img_read)
        file_download.close
      end

      p = Politician.where(name:name,party:party).first
      p.profile_photo = File.open(Rails.root + img_to)
      if p.save
        #printf "====== 디비 추가: #{img_src}"
      else
        printf "=== 사진 다운 : #{img_src}"
      end
    rescue
      printf "========= 실패: #{name}(#{party})\n"
    end 
  end
end
