# encoding: utf-8
require 'rails'
require 'csv'

# todo-list
=begin
  디렉토리 구분 + 동명이인 구분
=end

def calculate_percent(name)
  count = 5 # 출력할 공동 발의 의원수

  file_name = "laws_" + name.encode("utf-8") + ".csv"
  file_path = "./public/csvs/"

  members = Array.new
  hash = Hash.new(0)
  total = 0 # 전체 발의 의원수

  f = CSV.foreach(file_path + file_name) do |line|
    total += 1
    line[10].split(",").each do |member|
      if (name == member.force_encoding("UTF-8"))
      else
        hash[member] += 1 
      end
    end
  end

  puts "\n#{name}의원(대표발의 #{total}건)의 공동 발의 횟수가 많은 #{count}명\n\n"
  hash.values.sort.reverse[0..(count-1)].each do |top|
    puts "#{hash.key(top)}(#{top}건, #{100*top/total}%)" if total != 0
    hash[hash.key(top)] = 0
  end
end

# main
members = ["강길부","강명순","강석호","강성천","강승규","고승덕","고흥길","공성진","구상찬","권경석","권성동","권영세","권영진","권택기","김광림","김금래","김기현","김동성","김무성","김선동1","김선동2","김성동","김성수","김성식","김성조","김성태","김성회","김세연","김소남","김영선","김옥이","김용태","김장수","김재경","김정권","김정훈","김충환","김태원","김태환","김학송","김학용","김형오","김호연","김효재","나경원","나성린","남경필","박대해","박민식","박보환","박상은","박순자","박영아","박종근","박준선","박진","배영식","배은희","백성운","서병수","서상기","성윤환","손범규","손숙미","송광호","신상진","신성범","신지호","심재철","안경률","안형환","안홍준","안효대","여상규","원유철","원희룡","원희목","유기준","유승민","유일호","유재중","유정현","윤상현","윤영","이경재","이군현","이두아","이명규","이범관","이범래","이병석","이사철","이상권","이상득","이성헌","이애주","이윤성","이은재","이인기","이재오","이정선","이정현","이종혁","이주영","이진복","이철우","이춘식","이한성","이해봉","이혜훈","이화수","임동규","임해규","장광근","장윤석","장제원","전여옥","전재희","정두언","정몽준","정미경","정병국","정양석","정의화","정진섭","정태근","정희수","조문환","조원진","조윤선","조전혁","조진래","조진형","조해진","주광덕","주성영","주호영","진성호","진수희","진영","차명진","최경희","최구식","최병국","한기호","한선교","허원제","허천","허태열","현경병","현기환","홍사덕","홍일표","홍정욱","홍준표","황영철","황우여","황진하","김을동","김혜성","노철래","송영선","윤상일","정영희","심대평"]
members += ["이용경"]
members += ["윤석용","윤진식","이종구","정갑윤","정옥임","정해걸"]
members += ["김영우","안상수","이학재","강기갑","곽정숙","권영길","이정희","홍희덕","강기정","강봉균","강창일","김동철","김부겸","김상희","김성곤","김영록","김영진","김영환","김우남","김유정","김재균","김재윤","김진애","김진표","김춘진","김충조","김효석","김희철","노영민","문학진","문희상","박기춘","박병석","박상천","박선숙","박영선","박주선","박지원","백원우","백재현","변재일","서종표","신건","신낙균","신학용","안규백","안민석","양승조","오제세","우윤근","우제창","원혜영","유선호","이강래","이낙연","이석현","이성남","이용섭","이윤석","이종걸","이찬열","이춘석","장세환","전병헌","전현희","전혜숙","정동영","정범구","정세균","정장선","조경태","조배숙","조영택","조정식","주승용","천정배","최규성","최규식","최문순","최영희","최인기","최재성","추미애","홍영표","홍재형","유성엽","정수성","최연희","조승수","박우순","김창수","이명수","유원일","장병완", "조승수"]
members += ["신영수","김성순","송훈석"]
members += ["박근혜", "유정복", "이한구", "최경환", "강성종", "박은수", "송민순", "이미경", "최종원", "강용석", "박희태", "이인제", "김정", "정하균", "권선택", "김낙성", "김용구", "류근찬", "변웅전", "이상민", "이영애1","이영애2","이용희", "이재선", "이진삼", "이회창", "임영호", "조순형"]
members.each do |member|
 calculate_percent member
end
