require "rubygems"
require "bundler/setup"
require "sinatra"

get '/hi' do
  "Hello world!"
end
