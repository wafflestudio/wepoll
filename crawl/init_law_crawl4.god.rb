ruby_path = "/Users/tantara/.rvm/rubies/ruby-1.9.2-p290/bin/ruby"
God.watch do |w|
  w.dir = Dir.pwd
  w.name = "init_law_crawler"
  w.start = "#{ruby_path} init_law4.rb"
  w.log = "crawl4.log"
  w.keepalive
end
