ruby_path = "/Users/drh/.rvm/rubies/ruby-1.9.2-p290/bin/ruby"
crawler_path = "/Users/drh/Project/wepoll/crawl/init_law.rb"
working_dir = "/Users/drh/Project/wepoll/crawl/" #trailing / is IMPORTANT!
log_path = "/Users/drh/Project/wepoll/crawl/log"
God.watch do |w|
	w.name = "init_law_crawler"
	w.start = "#{ruby_path} #{crawler_path} #{working_dir}"
	w.log = log_path
	w.keepalive
end
