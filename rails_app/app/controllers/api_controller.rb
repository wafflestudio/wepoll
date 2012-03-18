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
		
		preview = Preview.where(:url => target_link).first
	 	# short url 처리

	 	if preview == nil 
			response = Timeout::timeout(10) do
				Net::HTTP.get_response(URI(target_link))
			end

			if response == Net::HTTPRedirection then
				target_link = response['location']
				preview = Preview.where(:url => target_link).first
			end
		end
		#preview = Preview.where(:url => target_link).first
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
			elsif target_link.match('news\.hankooki\.com') #한국일보
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
			elsif target_link.match('www\.dt\.co\.kr') #디지털타임스
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = doc.xpath('//meta[@property="me2:post_body"]').first['content'] 
				url_time = target_link.match(/article_no=\d*/).to_s.match(/\d\d\d\d\d\d\d\d/).to_s
				result[:image] = '' #못하겠다. 파싱을 못해... 
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2]	    

			elsif target_link.match('www\.koreatimes\.co\.kr') #korea times
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
				
			elsif target_link.match('www\.ytn\.co\.kr') # ytn
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('www\.dailian\.co\.kr') # 데일리안
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('koreajoongangdaily\.joinsmsn\.com') # 중앙데일리
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('www\.edaily\.co\.kr') # 이데일리
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = doc.xpath('//span[@id="content"]').text 
				if doc.xpath('//table[@align="left"]//table//img').length > 0
					result[:image] = doc.xpath('//table[@align="left"]//table//img').first['src']
				elsif doc.xpath('//table[@align="center"]//table//img').length > 0
					result[:image] = doc.xpath('//table[@align="center"]//table//img').first['src']
				elsif doc.xpath('//table[@align="right"]//table//img').length > 0
					result[:image] = doc.xpath('//table[@align="right"]//table//img').first['src']
				else
					result[:image] = ''
				end
				result[:created_at] = doc.xpath('//div[@class="time"]').text.match(/\d\d\d\d.\d\d.\d\d \d\d:\d\d/).to_s

			elsif target_link.match('www\.nocutnews\.co\.kr') # 노컷뉴스
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('mydaily\.co\.kr') # 마이데일리
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('sports\.donaga\.com') # 스포츠 동아닷컴
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('www\.reuters\.com') # 로이터
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('news\.inuews24\.com') # inews 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('osen\.mt\.co\.kr') # Osen 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''

			elsif target_link.match('biz\.heraldm\.com') #헤럴드 경제
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.xpath('//meta[@name="title"]').first['content']
				result[:description] =  doc.xpath('//div[@id="NewsAdContent"]').text.gsub(/\r/, '').gsub(/  /, '').gsub(/\n/, '')
				if  doc.xpath('//center/img').length > 0
					result[:image] =  doc.xpath('//center/img').first['src']
				else 
					result[:image] = ''
				end
				result[:created_at] = doc.xpath('//p[@class="dt"]').text

			elsif target_link.match('asiae\.co\.kr') # 아시아경제
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = doc.xpath('//div[@id="articleTxt"]').text.gsub(/\r\n/, '').gsub(/\t/, '').gsub(/<!--.*-->/, '')
				result[:image] = '' # 파싱 불가능. 스크립트로 불러오는거임 
				result[:created_at] = doc.xpath('//div[@class="tit"]/p').text.match(/\d\d\d\d.\d\d.\d\d \d\d:\d\d/).to_s
			elsif target_link.match('koreaherald\.com') # 코리아 헤럴드
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('realtime\.wsj\.com') # 코리아 리얼타임 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('cast\.wowtv\.co\.kr') # 한국경제 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('isplus\.joinsman\.com') # 일간스포츠
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('news\.sportsseoul\.com') #스포츠서울
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('www\.sportalkorea\.com') #스포탈 코리아 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('economy\.hankooki\.com') # 서울경제 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.xpath('//div[@id="GS_Title"]').text
				result[:description] = doc.xpath('//div[@id="GS_Content"]').text.gsub(/\r\n/, '').gsub(/\t/, '')
				if doc.xpath('//div[@id="Url_GisaImgNum_1"]').length > 0 
					result[:image] = doc.xpath('//div[@id="Url_GisaImgNum_1"]').text
				else
					result[:image] = ''
				end
				result[:created_at] = doc.xpath('//div[@id="magazine_all"]/script').text.match(/\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d/).to_s
			elsif target_link.match('www\.zdnet\.co\.kr') # zdnet 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('www\.bloter\.net') #불로터 닷 넷 
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:description] = '' 
				result[:image] = ''
				result[:created_at] = ''
			elsif target_link.match('www\.naeil\.com') #내일신문
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.xpath('//td[@class="titleArticle"]').text.gsub(/\r\n/, '').gsub(/  /, '').gsub(/\t/, '')
				result[:description] = doc.xpath('//div[@id="_article"]').text.gsub(/\r\n/, '').gsub(/\r/, '').gsub(/\t/, '')
				if doc.xpath('//center/img').length > 0 
					result[:image] = doc.xpath('//center/img').first['src'] 
				else 
					result[:image] = ''
				end
				result[:created_at] = doc.xpath('//td[@align="right"]').text.gsub(/\r\n/, '').gsub(/  /, '').gsub(/\t/, '').gsub(/[^\d-: ]/, '')
			elsif target_link.match('www\.etnews\.com') #전자신문
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = get_og_title doc
				result[:description] =  doc.xpath('//div[@id="articleBody"]/p').text.gsub(/\r/, '') 
				result[:image] = ''
				result[:created_at] = doc.xpath('//div[@id="articleTiile"]/div[@class="text_box"]/p').first.text.match(/\d\d\d\d.\d\d.\d\d/).to_s
			elsif target_link.match('www\.segye\.com') #세계일보
				doc = Nokigori::HTML(open(target_link))
				result[:title] = doc.title()
				url_time = target_link.match(/\d\d\d\d\d\d\d\d/)
				result[:created_at] = url_time[0,4] + '.' + url_time[4,2] + '.' + url_time[6,2] 	    
				if doc.xpath('//center/img').length > 0
					result[:image] = doc.xpath('//center/img').first['src']
				else
					result[:image] = ''
				end
				result[:description] = doc.xpath('//div[@id="SG_ArticleContent"]').text.gsub(/\r\n/, '').gsub(/\t/, '')
			elsif target_link.match('www\.fnnews\.com') #파이낸셜 뉴스,  
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:created_at] =  doc.xpath('//p[@class="update"]').text.match(/\d\d\d\d-\d\d\-\d\d \d\d:\d\d/).to_s
				if doc.xpath('//div[@class="news_content"]//table//table//img').length > 0
					result[:image] = doc.xpath('//div[@class="news_content"]//table//table//img').first['src']
				else
					result[:image] = ''
				end
				result[:description] = doc.xpath('//div[@class="news_content"]').text
			elsif target_link.match('www\.assembly\.go\.kr') # 국회방송?> natv
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.xpath('//div[@class="news-title-group"]/h5').text
				result[:created_at] = doc.xpath('//div[@class="news-title-group"]/span').text
				result[:description] =  doc.xpath('//div[@class="news-cont-group"]').text.gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '').gsub(/  /, '')
				result[:image] = '' #없는듯..  
			elsif target_link.match('mbn\.mk\.co\.kr') #mbn
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
				str =  doc.xpath('//div[@class="write"]/span[@class="reg_dt"]').text
				str[0..4] = ''
				result[:created_at] = str
			elsif target_link.match('news\.jtbc\.co\.kr') #jtbc
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = get_og_title doc
				result[:image] = get_og_image doc
				result[:description] = get_og_description doc
				str = doc.xpath('//span[@class="i_date"]').text
				str[0..2] = ''
				result[:created_at] = str
			elsif target_link.match('news\.tv\.chosun\.com') #tv 조선
				doc = Nokogiri::HTML(open(target_link))
				result[:image] = get_og_image doc
				result[:title] = doc.xpath('//div[@class="titleArea"]/h2').text.gsub(/\r/, '').gsub(/\t/, '').gsub(/\n/, '')
				result[:created_at] = doc.xpath('//p[@class="articleDate"]').text.gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '')
				doc.at('body').search('script, noscript, style, a').remove
				result[:description] =  doc.xpath('//div[@class="articleStory"]').text.gsub(/\t/, '').gsub(/\r/, '').gsub(/\n/, '')
			elsif target_link.match('news\.ichannela\.com') # A channel
				doc = Nokogiri::HTML(open(target_link))
				result[:title] = doc.title()
				result[:created_at] = doc.xpath('//div[@class="title"]/p').text.match(/\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/).to_s
				result[:description] = doc.xpath('//div[@class="article"]').text.gsub(/\r/, '').gsub(/\n/,'').gsub(/\t/,'')
				result[:image] = doc.xpath('//link[@rel="image_src"]').first['href']  #그냥 채널 A이미지.. ㅋㅋ
			elsif target_link.match('tistory\.com') # tistory
			  doc = Nokogiri::HTML(open(target_link))
			  result[:title] =  doc.xpath('//div[@class="titleWrap"]//a').first.text
			  if doc.xpath('//div[@class="titleWrap"]//span[@class="info"]').length > 0
			  	result[:created_at] = doc.xpath('//div[@class="titleWrap"]//span[@class="info"]').first.text.gsub(/\t/, '').gsub(/\n/, '').gsub(/\r/,'')
			  elsif doc.xpath('//div[@class="titleWrap"]//span[@class="date"]').length > 0
			  	result[:created_at] = doc.xpath('//div[@class="titleWrap"]//span[@class="date"]').first.text.gsub(/\t/, '').gsub(/\n/, '').gsub(/\r/,'')
			  else
			  	result[:created_at] = ''
			  end
			  if doc.xpath('//div[@class="imageblock center"]//img').length > 0
			  	result[:image] = doc.xpath('//div[@class="imageblock center"]//img').first['src']
			  elsif doc.xpath('//div[@class="imageblock left"]//img').length > 0
			  	result[:image] = doc.xpath('//div[@class="imageblock left"]//img').first['src']
			  elsif doc.xpath('//div[@class="imageblock right"]/img').length > 0
			  	result[:image] = doc.xpath('//div[@class="imageblock right"]//img').first['src']
			  else
			  	result[:image] = ''
			  end
			  doc.at('body').search('script').remove
			  if doc.xpath('//div[@class="article"]').length > 0
			  	result[:description] = doc.xpath('//div[@class="article"]').text.gsub(/\r/, '').gsub(/\n/, '').gsub(/\t/, '').gsub(/  /, '')
			 	elsif doc.xpath('//div[@class="desc"]').length > 0 
			 		result[:description] = doc.xpath('//div[@class="desc"]').text.gsub(/\r/, '').gsub(/\t/,'').gsub(/\n/,'').gsub(/  /, '') 
			 	end

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
