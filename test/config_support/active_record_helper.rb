# https://github.com/rails/rails/blob/master/guides/bug_report_templates/active_record_master.rb
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
# ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :email
    t.string :name
    t.float :latitude
    t.float :longitude
    t.datetime :registered_at
    t.text :preferences
  end

  create_table :posts, force: true do |t|
    t.integer :user_id
    t.string :title
    t.text :body
    t.integer :status
    t.boolean :verified
    t.date :published_on
    t.datetime :created_at
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
    t.text :body
    t.integer :likes, default: 0
  end
end

class User < ActiveRecord::Base
  serialize :preferences, Hash

  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments

  enum status: %i[draft published promoted landing]
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
