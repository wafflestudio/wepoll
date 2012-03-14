class Suggestion
  include Mongoid::Document
  field :name, :type => String
  field :content, :type => String
  field :email, :type => String
end
