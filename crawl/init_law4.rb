#coding:utf-8
require 'net/http'
require 'open-uri'
require 'iconv'
require 'nokogiri'
require 'csv'

iconv = Iconv.new("utf-8", "euc-kr")

unless File.exists? "list4.txt"
  puts "`list4.txt` must be in #{ARGV[0]}"
  exit 1
end

total_titles = File.readlines("list4.txt").map {|title| title.gsub /\n/, ''}

processed_titles = []
if File.exists? "complete_list4.txt"
  processed_titles = File.readlines("complete_list4.txt").map {|title| title.gsub /\n/, ''}
end

titles = total_titles - processed_titles

titles.each do |title|
  doc_raw = ""
  begin
    doc_raw = Net::HTTP.get(URI.parse("http://watch.peoplepower21.org/New/monitor_voteresult.php?kw="+URI.escape(title)))
  rescue
    puts "=====ERR : #{title} search failed====="
    exit 1
  end

  tmp_title = title
  c = 1
  while File.exists? "raw_data/law_list_#{tmp_title}_page1.html"
    tmp_title = title+"_#{c}"
    c+=1
  end
  title = tmp_title

  f = File.open("raw_data/law_list_#{title}_page1.html", "w")
  f.write doc_raw
  f.close

  doc = Nokogiri::HTML(doc_raw)
  
  #sub page
  begin 
    doc_path = doc.xpath('html/body/center/table/tr[4]/td/table/tr/td[3]/table[4]/tr/td/table/tr[2]/td[3]/a').attr('href').to_s
  rescue
    puts "=====ERR : Nil Link ====="
    f = File.open("complete_list4.txt", "a")
    f.puts title
    f.close
    exit 1
  end
  doc_raw = Net::HTTP.get(URI.parse(doc_path))

  tmp_title = title
  c = 1
  while File.exists? "raw_data/law_list_#{tmp_title}_sub_page1.html"
    tmp_title = title+"_#{c}"
    c+=1
  end
  title = tmp_title

  f = File.open("raw_data/law_list_#{title}_sub_page1.html", "w")
  f.write doc_raw
  f.close
  
  doc = Nokogiri::HTML(doc_raw)
  #end : sub page
  
  member = Array.new
  member += ["강길부","강명순","강석호","강성천","강승규","고승덕","고흥길","공성진","구상찬","권경석","권성동","권영세","권영진","권택기","김광림","김금래","김기현","김동성","김무성","김선동","김성동","김성수","김성식","김성조","김성태","김성회","김세연","김소남","김영선","김옥이","김용태","김장수","김재경","김정권","김정훈","김충환","김태원","김태환","김학송","김학용","김형오","김호연","김효재","나경원","나성린","남경필","박대해","박민식","박보환","박상은","박순자","박영아","박종근","박준선","박진","배영식","배은희","백성운","서병수","서상기","성윤환","손범규","손숙미","송광호","신상진","신성범","신지호","심재철","안경률","안형환","안홍준","안효대","여상규","원유철","원희룡","원희목","유기준","유승민","유일호","유재중","유정현","윤상현","윤영","이경재","이군현","이두아","이명규","이범관","이범래","이병석","이사철","이상권","이상득","이성헌","이애주","이윤성","이은재","이인기","이재오","이정선","이정현","이종혁","이주영","이진복","이철우","이춘식","이한성","이해봉","이혜훈","이화수","임동규","임해규","장광근","장윤석","장제원","전여옥","전재희","정두언","정몽준","정미경","정병국","정양석","정의화","정진섭","정태근","정희수","조문환","조원진","조윤선","조전혁","조진래","조진형","조해진","주광덕","주성영","주호영","진성호","진수희","진영","차명진","최경희","최구식","최병국","한기호","한선교","허원제","허천","허태열","현경병","현기환","홍사덕","홍일표","홍정욱","홍준표","황영철","황우여","황진하","김을동","김혜성","노철래","송영선","윤상일","정영희","심대평"]
  member += ["이용경"]
  member += ["윤석용","윤진식","이종구","정갑윤","정옥임","정해걸"]
  member += ["김영우","안상수","이학재","강기갑","곽정숙","권영길","이정희","홍희덕","강기정","강봉균","강창일","김동철","김부겸","김상희","김성곤","김영록","김영진","김영환","김우남","김유정","김재균","김재윤","김진애","김진표","김춘진","김충조","김효석","김희철","노영민","문학진","문희상","박기춘","박병석","박상천","박선숙","박영선","박주선","박지원","백원우","백재현","변재일","서갑원","서종표","신건","신낙균","신학용","안규백","안민석","양승조","오제세","우윤근","우제창","원혜영","유선호","이강래","이낙연","이석현","이성남","이용섭","이윤석","이종걸","이찬열","이춘석","장세환","전병헌","전현희","전혜숙","정동영","정범구","정세균","정장선","조경태","조배숙","조영택","조정식","주승용","천정배","최규성","최규식","최문순","최영희","최인기","최재성","최철국","추미애","홍영표","홍재형","유성엽","정수성","최연희","조승수","박우순","김창수","이명수","유원일","장병완", "조승수"]
  member += ["신영수","김성순","송훈석"]
  member += ["박근혜", "유정복", "이한구", "최경환", "강성종", "박은수", "송민순", "이미경", "최종원", "강용석", "박희태", "이인제", "김정", "정하균", "권선택", "김낙성", "김용구", "류근찬", "변웅전", "이상민", "이영애", "이용희", "이재선", "이진삼", "이회창", "임영호", "조순형"]

  group = Array.new

  1.upto(157).each do |i| group << "한나라당" end
  1.upto(6).each do |i| group << "미래희망연대" end
  group << "국민중심연합"
  group << "창조한국당"
  1.upto(9).each do |i| group << "한나라당" end
  1.upto(5).each do |i| group << "민주노동당" end
  1.upto(79).each do |i| group << "민주당" end
  1.upto(3).each do |i| group << "무소속" end
  group += ["통합민주당", "자유선진당", "자유선진당", "창조한국당", "대통합민주신당", "진보신당", "한나라당", "민주당", "무소속"]
  1.upto(4).each do |i| group << "한나라당" end
  1.upto(5).each do |i| group << "민주당" end
  1.upto(3).each do |i| group << "무소속" end
  1.upto(2).each do |i| group << "미래희망연대" end
  1.upto(14).each do |i| group << "자유선진당" end
  
    #각 의견에 대해..
  CSV.open("laws_#{title}.csv", "w") do |csv|
#    puts member.count
#    puts group.count

    csv << ["", "", "", ""] +  member
    csv << ["날짜", "의안 번호", "이슈", "법안명"] + group

    row = doc.xpath("html/body/center/table/tr/td/table/tr/td[2]/table[3]/tr/td/table/tr/td/table")

    #summary = row.xpath("tr[1]/td/b").to_s.strip.sub("<b>", "").sub("</b>", "")
    #summary_num = row.xpath("tr[1]/td").children[6].to_s.strip
    date = row.xpath("tr[1]/td").children[6].to_s.strip[0..9]
    code = ""
    issue = ""
    opinion = Array.new(298){0}
    detail = row.xpath("tr[1]/td/a").attr('href').to_s

    num = Array.new
    2.upto(7).each do |i| #찬성, 기권, 불참, 출장, 청가, 결석
      #group_member = Array.new
      #opinion = row.xpath("tr[#{i}]/td[1]").children[0].to_s.strip
      num = row.xpath("tr[#{i}]/td[1]").children[2].to_s.strip.sub("(", "").sub("명)", "")
      # group << row.xpath("tr[#{i}]/td[2]/b").to_s.strip
      # group << row.xpath("tr[#{i}]/td[2]/a").children[1].to_s.strip.sub(": ", "").sub("명 (", "")
      0.upto(num.to_i).each do |j|
        index = i - 1
#        puts row.xpath("tr[#{i}]/td[2]/a").children[j].to_s.strip
#        puts member.index(row.xpath("tr[#{i}]/td[2]/a").children[j].to_s.strip)
        opinion[member.index(row.xpath("tr[#{i}]/td[2]/a").children[j].to_s.strip)] = index.to_s if !member.index(row.xpath("tr[#{i}]/td[2]/a").children[j].to_s.strip).nil?
      end
    end #end of opinion
    csv << [date, code, issue, title] + opinion
  end #end of CSV

  f = File.open("complete_list4.txt", "a")
  f.puts title
  f.close
end
