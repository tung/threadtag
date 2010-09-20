require "rubygems"
require "bundler/setup"

require "sinatra"
require "sinatra/sequel"

# Connect to database.
set :database, ENV['DATABASE_URL'] || 'sqlite://threadtag.db'


### MIGRATIONS

migration "create threadtag table" do
  database.create_table :threadtag do
    String   :board, :size => 16
    Integer  :thread
    String   :tag, :size => 32
    String   :ip, :size => 16
    DateTime :updated_at

    primary_key [:board, :thread, :tag, :ip]
    index :board
    index [:board, :thread]
    index [:board, :tag]
  end
end


### APP

get '/hi' do
  "Hello world!"
end
