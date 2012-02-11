class TweetReply
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String

  field :recommend_count, type: Integer, default: 0 # 추천
  field :opposite_count, type: Integer, default: 0  # 반대
  field :report_count, type: Integer, default: 0    # 신고

  field :vote_ips, type: Array, default: []


  belongs_to :user


  def recommend(ip)
    if vote_ips.include? ip
      false
    else
      self.recommend_count += 1
      vote_ips << ip
    end
  end

  def opposite(ip)
    if vote_ips.include? ip
      false
    else
      self.opposite_count += 1
      vote_ips << ip
    end
  end
  def report(ip)
    if vote_ips.include? ip
      false
    else
      self.report_count += 1
      vote_ips << ip
    end
  end

end
