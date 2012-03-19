#encoding: utf-8
require 'net/http'
require 'open-uri'
require 'iconv'
require 'nokogiri'
require '../romanize'

total = 2659
iconv = Iconv.new("utf-8", "euc-kr")

2000.upto(total) do |i|
  begin
    url = "http://www.rokps.or.kr/profile_result_ok.asp?num=#{i}"
    img_src = "http://www.rokps.or.kr/images/user/#{i}.jpg"

    begin
      doc = iconv.iconv(Net::HTTP.get(URI.parse(url)))

      raw = Nokogiri::HTML(doc)
      name = raw.xpath("html/body/table/tr[4]/td/table/tr/td[4]/table/tr/td/table/tr/td[2]").children[2].to_s.encode("utf-8")[0..2].sub("(","")
      name = name.romanize

      begin
   #     img_read = open(img_src).read
        img_to = "profile/#{name}"

        1.upto(30) do |j|
          if File.exists?(img_to+".jpg")
            img_to = img_to + "_#{j}"
            puts "#{i} -- #{url}" if j == 1 && name.empty?
          else
            break
          end
        end

        puts "#{i} -- #{img_to}"
#        file_download = open(img_to+".jpg", "wb")
#        file_download.write(img_read)
#        file_download.close
      rescue
        puts "#{img_src} 실패"
      end
    rescue
      puts "#{url} 실패"
    end
  end
end
