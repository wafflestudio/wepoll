#coding: utf-8
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
	 # short url 처리 
		response = Net::HTTP.get_response(URI(target_link))	
		if response == Net::HTTPRedirection then
			target_link = response['location']
		end
		preview = Preview.where(:url => target_link).first
		result = {}
		if preview != nil
			result[:creasted_at] = preview.created
			result[:title] = preview.title
			result[:description ] = preview.description
			result[:image] = preview.image_url
		else
			doc = Nokogiri::HTML(open(target_link))
			#무슨 기사인지 판별.  
			if target_link.match('news\.chosu.\.com') != nil #조선일보 
				result[:created_at] = doc.xpath('//p[@id="date_text"]').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/  /, '')
				result[:title] = doc.title()
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
				result[:image] = doc.xpath('//div[@id="img_pop0"]/dl/div/img').first['src'] if doc.xpath('//div[@id="img_pop0"]/dl/div/img').count > 0
			elsif target_link.match('news\.kbs\.co\.kr') != nil #케이비에스 
				result[:created_at] = doc.xpath('//p[@class="newsUpload"]/em').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/  /, '')
				result[:title] = doc.xpath('//meta[@name="title"]').first['content']
				result[:description] = doc.xpath('//div[@id="newsContents"]').first.text.gsub(/\r\n/, '').gsub(/  /, '') 
				result[:image] = doc.xpath('//link[@rel="image_src"]').first['src']
			elsif target_link.match('www\.munhwa\.com') != nil #문화일보 
				result[:created_at] = target_link.match(/[\d]+/).to_s[0,8] #yyyymmdd 
				#result[:created_at] = doc.xpath('//td[@align="right"]').text
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
			elsif target_link.match('hankyung\.com') != nil #한국경제
				result[:created_at] = doc.xpath('//div[@class="tabBox"]/span').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				doc.at('body').search('script, noscript, style, a').remove
				result[:description] = doc.xpath('//div[@id="newsView"]').text.gsub(/  /, '').gsub(/\t/, '').gsub(/\r\n/, '')
				if false
					doc.xpath('//div[@id="newsView"]').each do |para|
							para.text.gsub(/\t/, '').gsub(/  /, '').split(/\r\n/).each do |p|
									result[:description] += p.gsub(/\t/, '')
							end
					end
				end
			elsif target_link.match('pressian\.com') != nil #프레시안
				result[:created_at] = doc.xpath('//p[@class="inputdate"]').text
				result[:title] = doc.title()
				if doc.xpath('//div[@id="newsBODY"]/table/tbody/tr/td/img').count > 0 
					result[:image] = doc.xpath('//div[@id="newsBODY"]/table/tbody/tr/td/img').first['src']
				else 
					result[:image] = ''
				end
				doc.at('body').search('script, noscript, style').remove
				result[:description] = doc.xpath('//div[@id="newsBODY"]').text.gsub(/\r\n/, '').gsub(/\t/, '')
			elsif target_link.match('kukinews\.com') != nil #국민일보  얘 좀 이상해...
				result[:created_at] = doc.xpath('//li[@class="date"]').text
				result[:title] = doc.xpath('//meta[@property="og:title"]').first['content'] if doc.xpath('//meta[@property="og:title"]').count > 0
				result[:description] = doc.xpath('//div[@id="_article"]').text
				if doc.xpath('//meta[@property="og:image"]').count > 0
					result[:image] = doc.xpath('//meta[@property="og:image"]').first['content']
				else 
					result[:image] = ''
				end
			elsif target_link.match('news\.donga\.com') != nil #동아일보
				result[:created_at] =  '기사 입력 : ' + doc.xpath('//span[@class="infoInput"]').text + '| 최종 수정 : ' +  doc.xpath('//span[@class="infoModify"]').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="me2:image"]').first['content']
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
			elsif target_link.match('news\.khan\.co\.kr') != nil #경향신문
				result[:created_at] = doc.xpath('//div[@class="article_date"]').text.gsub(/  /, '').gsub(/\t/, '').gsub(/\r\n/, '')
				result[:title] = doc.title()
				if doc.xpath('//div[@class="article_photo"]/img').count > 0
					result[:image] = doc.xpath('//div[@class="article_photo"]/img').first['src']
				else
					result[:image] = ''
				end
				result[:description] = doc.xpath('//span[@class="article_txt"]').text.gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
			elsif target_link.match('www\.ohmynews\.com') != nil #오 마이뉴스
				result[:created_at] =  doc.xpath('//body').text.match(/\d\d\.\d\d\.\d\d\ \d\d:\d\d/).to_s
				result[:title] = doc.title().gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'].gsub(/\r/, '').gsub(/\t/, '').gsub(/  /, '')
			elsif target_link.match('news\.sbs\.co\.kr') != nil #sbs
				result[:created_at] = doc.xpath('//p[@class="lastDate"]').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:description] =  doc.xpath('//meta[@name="Description"]').first['content']
			elsif target_link.match('joongang\.joinsmsn\.com') != nil #중앙일보
				result[:created_at] = doc.xpath('//span[@class="date"]').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'] 
			elsif target_link.match('imnews\.imbc\.com') != nil  #MBC
				result[:created_at] = doc.xpath('//span[@class="news_data"]').text
				result[:title] = doc.xpath('//meta[@name="title"]').first['content']
				result[:image] = ''
				result[:description] = doc.xpath('//div[@class="txt_frame"]/p').text.gsub(/\r/, '')
			elsif target_link.match('news\.naver\.com') #naver
				result[:created_at] = doc.xpath('//div[@class="article_header"]/div/span[@class="t11"]').text
				result[:title] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
			elsif target_link.match('media\.daum\.net') #daum 
				url_time = get_og_url doc 
				url_time = url_time.match(/[\d]+/).to_s
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2] + '.' + url_time[6,2] + ' ' + url_time[8,2] + ':' + url_time[10,2]
				result[:title ] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
			elsif target_link.match('news\.nate\.com')  #nate
				url_time = target_link.match(/[\d]+/).to_s
				#result[:created_at] = doc.xpath('//span[@class="firstDate"]').text
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2] + '.' + url_time[6,2] 	    
				result[:title] = doc.title()
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
				result[:image] = doc.xpath('//div[@id="articleImage0"]/span/img').first['src'] if doc.xpath('//div[@id="articleImage0"]/span/img').count > 0
			else
				result[:error] = '해당 기사는 지원되지 않습니다.'
				#result[:title] = doc.title()
				#result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				#result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'] if doc.xpath('//meta[@property="og:description"]').count > 0
				#result[:created_at] = ''
			end
			Preview.create(:url => target_link, :title => result[:title], :image_url => result[:image], :description => result[:description], :created => result[:created_at])
		end
		render :json => result.to_json
	end

	def youtube_parsing
		target_url = params[:url]
		doc = Nokogiri::HTML(open(target_url))
		result = {}
		result[:embed_url] = doc.xpath('//div[@id="content"]/div[@id="watch-container"]/link[@itemprop="embedURL"]').first['href']

		render :json => result.to_json
	end

private
	def get_og_title doc
		if  doc.xpath('//meta[@property="og:title"]').count > 0
			return doc.xpath('//meta[@property="og:title"]').first['content']
		else
		  return ''
		end
	end

	def get_og_image doc
		if  doc.xpath('//meta[@property="og:image"]').count > 0
			return doc.xpath('//meta[@property="og:image"]').first['content']
		else
		  return ''
		end
	end

	def get_og_description doc
		if  doc.xpath('//meta[@property="og:description"]').count > 0
			return doc.xpath('//meta[@property="og:description"]').first['content']
		else
		  return ''
		end
	end

	def get_og_url doc
		if  doc.xpath('//meta[@property="og:url"]').count > 0
			return doc.xpath('//meta[@property="og:url"]').first['content']
		else
		  return ''
		end
	end

end
