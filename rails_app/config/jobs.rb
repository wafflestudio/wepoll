require File.expand_path("../environment", __FILE__)
require 'stalker'
include Stalker

job 'email.send' do |args|
  if args['type'] == 'sns_link_path'
    token = UserToken.find(args['token_id'])
    AuthMailer.link_sns_verification(token).deliver
  end
end
