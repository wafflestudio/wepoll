#coding:utf-8
class String
  # 한글 초성, 중성, 종성. (UTF-8 이어야 함)
  initial_letters_kor = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'.split('')
  initial_letters_eng = 'g,kk,n,d,tt,r,m,b,pp,s,ss,,j,jj,ch,k,t,p,h'.split(',')
  @@initial_letters = {}
  initial_letters_kor.each_with_index do |c,i|
    @@initial_letters[c] = initial_letters_eng[i]
  end

  peak_letters_kor = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'.split('')
  peak_letters_eng = 'a,ae,ya,yae,eo,e,yeo,ye,o,wa,wae,oe,yo,u,wo,we,wi,yu,eu,ui,i'.split(',')
  @@peak_letters = {}
  peak_letters_kor.each_with_index do |c,i|
    @@peak_letters[c] = peak_letters_eng[i]
  end


  final_letters_kor = 'ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ'.split('')
  final_letters_eng = 'k,kk,k,n,n,n,t,l,k,m,b,s,t,p,l,m,p,ps,t,t,ng,t,t,k,t,p,h'.split(',')
  @@final_letters = {}
  final_letters_kor.each_with_index do |c,i|
    @@final_letters[c] = final_letters_eng[i]
  end

  @@chosung = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
  @@jungsung = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ']
  @@jongsung = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
  # UTF-8 형식의 문자열을 분해하여 로마자로 변환함
  def romanize
    separated = []

    self.unpack('U*') do |c|
      n = (c & 0xFFFF).to_i

      # 유니코드 2.0 한글의 범위 : AC00(가) ~ D7A3(힣)
      if n >= 0xAC00 && n <= 0xD7A3
        n -= 0xAC00
        n1 = n / (21 * 28)  # 초성 : ‘가’ ~ ‘깋’ -> ‘ㄱ’
        n = n % (21 * 28)  # ‘가’ ~ ‘깋’에서의 순서
        n2 = n / 28;    # 중성
        n3 = n % 28;    # 종성

        separated << @@initial_letters[@@chosung[n1]] << @@peak_letters[@@jungsung[n2]] << @@final_letters[@@jongsung[n3]]
#        separated << @@chosung[n1] << @@jungsung[n2] << @@jongsung[n3]
      else
        separated << [c].pack('U')
      end
    end

    separated.join()
  end
end
