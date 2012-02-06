#coding:utf-8
class AuthMailer < ActionMailer::Base
  default from: "drh@wepoll.or.kr"

  def link_sns_verification(user_token)
    @user = user_token.user
    @user_token = user_token
    mail(to: user.email, subject: "위키폴리틱스 SNS 계정연동확인")
  end
end

