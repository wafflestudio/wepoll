class Preview
  include Mongoid::Document

  field :url, type: String
  field :title, type: String
  field :description, type: String
  field :image_url, type: String
  field :created, type: String

	index :url, unique: true
end
