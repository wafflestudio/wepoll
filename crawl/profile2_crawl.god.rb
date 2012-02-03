ruby_path = "/home/drh/.rvm/rubies/ruby-1.9.2-p290/bin/ruby"
God.watch do |w|
  w.dir = Dir.pwd
  w.name = "profile2_crawler"
  w.start = "#{ruby_path} profile2.rb"
  w.log = "crawl_profile2.log"
  w.keepalive
end
