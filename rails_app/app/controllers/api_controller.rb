class ApiController < ApplicationController

	require 'open-uri'
	def parsing_test
			target_link = params[:url]
			doc = Nokogiri::HTML(open(target_link))
			arr = {}
			doc.xpath('//title').each do |title|
					arr[:title] = title.content
					arr[:title_path] = title.path
			end
			render :json => arr.to_json
	end

	#기사 파싱하는 api    input : url
	#											output : title, image, description // json형식
	def article_parsing
		target_link = params[:url]
		doc = Nokogiri::HTML(open(target_link))
		result = {}
		#무슨 기사인지 판별.  
		if target_link.match('news\.chosu.\.com') != nil #조선일보 
			result[:title] = doc.title()
			result[:description] = doc.xpath('//meta[@name="description"]').first['content']
			result[:image] = doc.xpath('//div[@id="img_pop0"]/dl/div/img').first['src'] if doc.xpath('//div[@id="img_pop0"]/dl/div/img').count > 0
		elsif target_link.match('news\.kbs\.co\.kr') != nil #케이비에스 
			result[:title] = doc.xpath('//meta[@name="title"]').first['content']
			result[:description] = doc.xpath('//div[@id="newsContents"]').first.text.gsub(/\r\n/, '').gsub(/  /, '') 
			result[:image] = doc.xpath('//link[@rel="image_src"]').first['src']
		elsif target_link.match('www\.munhwa\.com') != nil #문화일보 
			result[:title] = doc.title()
			doc.xpath('//div[@id="NewsAdContent"]').each do |para|
					para.text.split(/\r\n/).each do |p|
						if p.gsub(/\t/, '').length >=100
							result[:description] = p.gsub(/\t/, '')
							break
						end
					end
			end
			if doc.xpath('//td[@align="center"]/img').count > 0 
				result[:image] = doc.xpath('//td[@align="center"]/img').first['src']
			else
				result[:image] = ''
			end
		elsif target_link.match('new\.hankyung\.com') != nil #한국경제
 			result[:title] = doc.title()
 			result[:image] = doc.xpath('//meta[@property="go:image"]').first['content']
			doc.xpath('//div[@id="CLtag"]/div').each do |para|
					para.text.split(/\r\n/).each do |p|
						if p.gsub(/\t/, '').length >=100
							result[:description] = p.gsub(/\t/, '')
							break
						end
						break
					end
			end
		elsif target_link.match('www\.pressian\.com') != nil #프레시안
			result[:title] = doc.title()
			if doc.xpath('//div[@id="newsBODY"]/table/tbody/tr/td/img').count > 0 
				result[:image] = doc.xpath('//div[@id="newsBODY"]/table/tbody/tr/td/img').first['src']
			else 
				result[:image] = ''
			end
			doc.at('body').search('script, noscript, style').remove
			result[:description] = doc.xpath('//div[@id="newsBODY"]').text.gsub(/\r\n/, '').gsub(/\t/, '')
		elsif target_link.match('news\.kukinews\.com') != nil #국민일보  얘 좀 이상해...
			result[:title] = doc.xpath('//meta[@property="og:title"]').first['content']
			result[:description] = doc.xpath('//div[@id="_article"]').text
			if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content']
			else 
				result[:image] = ''
			end
		elsif target_link.match('news\.donga\.com') != nil #동아일보
			result[:title] = doc.title()
			result[:image] = doc.xpath('//meta[@property="me2:image"]').first['content']
			result[:description] = doc.xpath('//meta[@name="description"]').first['content']
		elsif target_link.match('news\.khan\.co\.kr') != nil #경향신문
			result[:title] = doc.title()
			if doc.xpath('//div[@class="article_photo"]/img').count > 0
				result[:image] = doc.xpath('//div[@class="article_photo"]/img').first['src']
			else
				result[:image] = ''
			end
			result[:description] = doc.xpath('//span[@class="article_txt"]').text.gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
		elsif target_link.match('www\.ohmynews\.com') != nil #오 마이뉴스
			result[:title] = doc.title().gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
			result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
			result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'].gsub(/\r/, '').gsub(/\t/, '').gsub(/  /, '')
		elsif target_link.match('news\.sbs\.co\.kr') != nil #sbs
			result[:title] = doc.title()
			result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
			result[:description] =  doc.xpath('//meta[@name="Description"]').first['content']
		elsif target_link.match('joongang\.joinsmsn\.com') != nil #중앙일보
			result[:title] = doc.title()
			result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
			result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'] 
		elsif target_link.match('imnews\.imbc\.com') != nil  #MBC
			result[:title] = doc.xpath('//meta[@name="title"]').first['content']
			result[:image] = ''
			result[:description] = doc.xpath('//div[@class="txt_frame"]/p').text.gsub(/\r/, '')
		else
			result[:title] = doc.title()
			result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
			result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'] if doc.xpath('//meta[@property="og:description"]').count > 0
		end
		render :xml => result.to_json
	end

end
