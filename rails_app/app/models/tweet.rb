class Tweet
  include Mongoid::Document

  field :name
  field :screen_name
  field :content, type: String
  field :created_at, type: DateTime

  field :recommend_count, type: Integer, default: 0       # 추천
  field :opposite_count, type: Integer, default: 0        # 반대
  field :today_recommend_count, type: Integer, default: 0 # 오늘의 추천
  field :vote_ips, type: Array, default: []


  has_many :tweet_replies
  belongs_to :politician


  def recommend(ip)
    if self.vote_ips.include? ip
      false
    else
      self.recommend_count = self.recommend_count+1
      self.today_recommend_count = self.today_recommend_count+1
      self.vote_ips << ip
      self.save
    end
  end

  def opposite(ip)
    if self.vote_ips.include? ip
      false
    else
      self.opposite_count = self.opposite_count+1
      self.vote_ips << ip
      self.save
    end
  end

end
