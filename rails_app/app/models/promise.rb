class Promise
  include Mongoid::Document

  field :title
  field :content
  field :election_count

  belongs_to :politician
  has_many :messages

end
