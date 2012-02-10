ruby_path = "~/.rvm/rubies/ruby-1.9.2-p290/bin/ruby"
God.watch do |w|
  w.dir = Dir.pwd
  w.name = "naver_crawler"
  w.start = "#{ruby_path} naver.rb"
  w.log = "naver_crawl.log"
  w.keepalive
end
