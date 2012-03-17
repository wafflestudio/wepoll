#coding: utf-8
require 'timeout'
require 'open-uri'
class ApiController < ApplicationController
	def parsing_test
			target_link = params[:url].gsub /&amp;/, '&'
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
		(render :nothing => true ;return) if params[:url].nil? || params[:url].strip.length == 0
		target_link = params[:url].gsub /&amp;/,'&'
		if !target_link.match(/^http:\/\//i)
			target_link = "http://" + target_link
		end

		# 자기 자신을 호출하는 걸 막아야함. Temporary measure
		domain = target_link[7..-1].split(/[\/?]/)[0]
		return if domain.match("wepoll.or.kr") || domain.match("choco.wafflestudio.net")
		
	 	# short url 처리
		response = Timeout::timeout(6) do
			Net::HTTP.get_response(URI(target_link))
		end

		if response == Net::HTTPRedirection then
			target_link = response['location']
		end
		preview = Preview.where(:url => target_link).first
		result = {}
		
		if preview != nil and !params[:force_get]
			result[:id] = preview.id
			result[:created_at] = preview.created
			result[:title] = preview.title
			result[:description ] = preview.description[0...117]  + "..."# 120자 제한!
			result[:image] = preview.image_url
		else
			#doc = Nokogiri::HTML(open(target_link))
			#무슨 기사인지 판별.  
			if target_link.match('news\.chosun\.com') != nil #조선일보 
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//p[@id="date_text"]').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/  /, '')
				result[:title] = doc.title()
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
				result[:image] = doc.xpath('//div[@id="img_pop0"]/dl/div/img').first['src'] if doc.xpath('//div[@id="img_pop0"]/dl/div/img').count > 0
			elsif target_link.match('biz\.chosun\.com') != nil #조선비즈
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = doc.xpath('//div[@id="article"]').text.gsub(/\r\n/, '').gsub(/\t/, '')
				result[:created_at] =  doc.xpath('//div[@class="date_ctrl"]/p').text.split(' ')[2] + ' ' +  doc.xpath('//div[@class="date_ctrl"]/p').text.split(' ') [3] 
				if  doc.xpath('//div[@class="center_img"]//img').length > 0 
					result[:image] =  doc.xpath('//div[@class="center_img"]//img').first['src']
				else
					result[:image] = ''
				end
			elsif target_link.match('news\.kbs\.co\.kr') != nil #케이비에스 
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//p[@class="newsUpload"]/em').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/  /, '')
				result[:title] = doc.xpath('//meta[@name="title"]').first['content']
				result[:description] = doc.xpath('//div[@id="newsContents"]').first.text.gsub(/\r\n/, '').gsub(/  /, '') 
				result[:image] = doc.xpath('//link[@rel="image_src"]').first['src']
			elsif target_link.match('www\.munhwa\.com') != nil #문화일보 
				doc = Nokogiri::HTML(open(target_link))
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
				doc = Nokogiri::HTML(open(target_link))
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
				doc = Nokogiri::HTML(open(target_link))
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
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//li[@class="date"]').text
				result[:title] = doc.xpath('//meta[@property="og:title"]').first['content'] if doc.xpath('//meta[@property="og:title"]').count > 0
				result[:description] = doc.xpath('//div[@id="_article"]').text
				if doc.xpath('//meta[@property="og:image"]').count > 0
					result[:image] = doc.xpath('//meta[@property="og:image"]').first['content']
				else 
					result[:image] = ''
				end
			elsif target_link.match('news\.donga\.com') != nil #동아일보
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] =  '기사 입력 : ' + doc.xpath('//span[@class="infoInput"]').text + '| 최종 수정 : ' +  doc.xpath('//span[@class="infoModify"]').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="me2:image"]').first['content']
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
			elsif target_link.match('news\.khan\.co\.kr') != nil #경향신문
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//div[@class="article_date"]').text.gsub(/  /, '').gsub(/\t/, '').gsub(/\r\n/, '')
				result[:title] = doc.title()
				if doc.xpath('//div[@class="article_photo"]/img').count > 0
					result[:image] = doc.xpath('//div[@class="article_photo"]/img').first['src']
				else
					result[:image] = ''
				end
				result[:description] = doc.xpath('//span[@class="article_txt"]').text.gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
			elsif target_link.match('www\.ohmynews\.com') != nil #오 마이뉴스
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] =  doc.xpath('//body').text.match(/\d\d\.\d\d\.\d\d\ \d\d:\d\d/).to_s
				result[:title] = doc.title().gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'].gsub(/\r/, '').gsub(/\t/, '').gsub(/  /, '')
			elsif target_link.match('news\.sbs\.co\.kr') != nil #sbs
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//p[@class="lastDate"]').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:description] =  doc.xpath('//meta[@name="Description"]').first['content']
			elsif target_link.match('joongang\.joinsmsn\.com') != nil #중앙일보
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//span[@class="date"]').text
				result[:title] = doc.title()
				result[:image] = doc.xpath('//meta[@property="og:image"]').first['content'] if doc.xpath('//meta[@property="og:image"]').count > 0
				result[:description] = doc.xpath('//meta[@property="og:description"]').first['content'] 
			elsif target_link.match('imnews\.imbc\.com') != nil  #MBC
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//span[@class="news_data"]').text
				result[:title] = doc.xpath('//meta[@name="title"]').first['content']
				result[:image] = ''
				result[:description] = doc.xpath('//div[@class="txt_frame"]/p').text.gsub(/\r/, '')
			elsif target_link.match('news\.naver\.com') #naver
				doc = Nokogiri::HTML(open(target_link))
				result[:created_at] = doc.xpath('//div[@class="article_header"]/div/span[@class="t11"]').text
				result[:title] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
			elsif target_link.match('media\.daum\.net') #daum 
				doc = Nokogiri::HTML(open(target_link))
				url_time = get_og_url doc 
				url_time = url_time.match(/[\d]+/).to_s
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2] + '.' + url_time[6,2] + ' ' + url_time[8,2] + ':' + url_time[10,2]
				result[:title ] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
			elsif target_link.match('news\.nate\.com')  #nate
				doc = Nokogiri::HTML(open(target_link))
				url_time = target_link.match(/[\d]+/).to_s
				#result[:created_at] = doc.xpath('//span[@class="firstDate"]').text
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2] + '.' + url_time[6,2] 	    
				result[:title] = doc.title()
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
				result[:image] = doc.xpath('//div[@id="articleImage0"]/span/img').first['src'] if doc.xpath('//div[@id="articleImage0"]/span/img').count > 0
			elsif target_link.match('wikitree\.co\.kr') # wikitree
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				if doc.xpath('//embed').length > 0 #has video 
					result[:video] = doc.xpath('//embed').first['src']
				else 
					if doc.xpath('//p[@align="center"]/img').length > 0
						result[:image] = doc.xpath('//p[@align="center"]/img').first['src'] 
					else
						result[:image] = ''
					end
				end
				result[:description] = doc.xpath('//div[@id="content1"]').text
				result[:created_at] = doc.xpath('//span[@class="date"]').text
			elsif target_link.match('seoul\.co\.kr/news') # 서울신문
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				if doc.xpath('//div[@id="img"]//img').length > 0
					result[:image] = doc.xpath('//div[@id="img"]//img').first['src']
				else
					result[:image] = ''
				end
				result[:created_at] = doc.xpath('//div[@class="VCdate"]').text
				result[:description] = doc.xpath('//div[@id="articleContent"]//p').first.text.gsub(/\r\n/, '').gsub(/\t/, '')
			elsif target_link.match('hani\.co\.kr') # 한겨례 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:created_at] = doc.xpath('//p[@class="date"]/span').first.text.split(' ')[2] + ' ' + doc.xpath('//p[@class="date"]/span').first.text.split(' ')[3]
				result[:description] =  doc.xpath('//div[@class="article-contents"]').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/\n/, '')
				if doc.xpath('//table[@class="photo-view-area"]//img').length > 0 
					result[:image] = doc.xpath('//table[@class="photo-view-area"]//img').first['src']
				else 
					result[:image] = ''
				end
			elsif target_link.match('mt\.co\.kr') #머니투데이 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.xpath('//meta[@name="og:title"]').first['content']
				if  doc.xpath('//td[@class="img"]//img').length >0
					result[:image] =  doc.xpath('//td[@class="img"]//img').first['src']
				else
					result[:image] = get_og_image doc
				end
				result[:description] = doc.xpath('//meta[@name="description"]').first['content']
				result[:created_at] = doc.xpath('//span[@class="num"]').text.match(/\d\d\d\d.\d\d.\d\d \d\d:\d\d/).to_s
			elsif target_link.match('hankooki\.com') #한국일보
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title().gsub(/\n/, '')
				if doc.xpath('//div[@id="Url_GisaImgNum_1"]').length > 0
					result[:image] = doc.xpath('//div[@id="Url_GisaImgNum_1"]').text
				else
					result[:image] = ''
				end
				result[:description] = doc.xpath('//div[@id="GS_Content"]').text.gsub(/\r\n/, '').gsub(/\t/, '')
				url_time = target_link.split('/').last.match(/\d\d\d\d\d\d\d\d\d\d\d\d/).to_s
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2] + '.' + url_time[6,2] + ' ' + url_time[8,2] + ':' + url_time[10,2]
			elsif target_link.match('mediatoday\.co\.kr')  #미디어 오늘:
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:created_at] = doc.xpath('//td[@align="right"]').text.gsub(/\r\n/, '').gsub(/\t/, '').match(/\d\d\d\d-\d\d-\d\d \d\d:\d\d/).to_s
				result[:description] =doc.xpath('//div[@id="media_body"]').text.gsub(/\t/, '').gsub(/\n/, '').gsub(/  /, '').gsub(/\r/, '')
				if doc.xpath('//td[@align="center"]/img').length > 0 
					result[:image] = doc.xpath('//td[@align="center"]/img').first['src']
				else 
					result[:image] = ''
				end
			elsif target_link.match('news\.mk\.co\.kr') # 매일경제
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
				result[:created_at] = doc.xpath('//span[@class="sm_num"]').text  #날짜가 안되네...
			elsif target_link.match('www\.yonhapnews\.co\.kr') ##연합뉴스 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = doc.xpath('//div[@id="articleBody"]').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/\/"/, '')
				if doc.xpath('//dt[@class="pto"]/img').length > 0 
					result[:image] = doc.xpath('//dt[@class="pto"]/img').first['src']
				else
					result[:image] = ''
				end
				result[:created_at] =  doc.xpath('//span[@class="pblsh"]').text.gsub(/[^\d\/: ]/, '')
#			elsif target_link.match('app\.yonhapnews\.co\.kr') ##연합뉴스, 영상포함  여기 그지같다. 하지 말아야ㅣㅈ .
#				result[:title] = doc.title()
#				result[:created_at] = doc.xpath('//li[@class="time"]').text
#				str = doc.xpath('//span[@id="spnmpic"]/script').text.match(/src="[^"]*/).to_s
#				str[0..4] = ''
#				result[:video] = str
#				result[:description] = 
			elsif target_link.match('newsis\.com') #뉴시스
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:created_at] = doc.xpath('//font[@class="text-666666-11"]').text
				result[:description] = doc.xpath('//div[@id="articleBody"]').text.gsub(/\r\n/, '')
				if doc.xpath('//div[@class="center_img"]/dl/img').length > 0
					result[:image] = doc.xpath('//div[@class="center_img"]/dl/img').first['src']
				else
					result[:image] = ''
				end
			elsif target_link.match('kr\.news\.yahoo\.com') #야후
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				if  doc.xpath('//link[@rel="image_src"]').length > 0 
					result[:image] =  doc.xpath('//link[@rel="image_src"]').first['href']
				else 
					result[:image] = ''
				end
				result[:description] = doc.xpath('//div[@id="content"]').text.gsub(/\n/, '').gsub(/\r/, '')
				result[:created_at] = doc.xpath('//span[@class="d1"]').text.gsub(/[^\d :]/, '')
			else
				result[:url] = target_link
				result[:error] = '해당 기사는 지원되지 않습니다.'
				render :json =>result.to_json, :status => 500
				return
			end
			preview = Preview.create(:url => target_link, :title => result[:title], :image_url => result[:image], :description => result[:description], :created => result[:created_at])
			result[:id] = preview.id
			if result[:description].length >= 120
				result[:description] = result[:description][0,117] + '...'
			end

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
