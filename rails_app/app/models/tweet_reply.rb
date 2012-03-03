class TweetReply
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String

  field :recommend_count, type: Integer, default: 0 # 추천
  field :report_count, type: Integer, default: 0    # 신고

  field :vote_ips, type: Array, default: []


  belongs_to :user
  belongs_to :tweet
  has_and_belongs_to_many :recommend_users, :class_name => "User", :inverse_of => :recommend_replies
  has_and_belongs_to_many :report_users, :class_name => "User", :inverse_of => :report_replies


  def recommend(user)
    if self.recommend_users.include? user
      false
    else
      self.recommend_count += 1
      self.recommend_users << user
      self.save
    end
  end

  def report(user)
    if self.report_users.include? user
      false
    else
      self.report_count += 1
      self.report_users << user
      self.save
    end
  end

end
