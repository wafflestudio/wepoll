class Tweet
  include Mongoid::Document

  field :status_id
  field :name
  field :screen_name
  field :content, type: String
  field :created_at, type: DateTime

  field :recommend_count, type: Integer, default: 0       # 추천
  field :today_recommend_count, type: Integer, default: 0 # 오늘의 추천


  has_many :tweet_replies
  belongs_to :politician
  has_and_belongs_to_many :recommend_users, :class_name => "User", :inverse_of => :recommend_tweets


  def recommend(user)
    if self.recommend_users.include? user
      false
    else
      self.recommend_count = self.recommend_count+1
      self.today_recommend_count = self.today_recommend_count+1
      self.recommend_users << user
      self.save
    end
  end
end
