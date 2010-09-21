require 'threadtag'
require 'bacon'
require 'rack/test'

class Bacon::Context
  include Rack::Test::Methods
end

describe "The ThreadTag App" do
  def app
    ThreadTag
  end

  it "says hello world" do
    get '/hi'
    last_response.should.be.ok
    last_response.body.should.equal "Hello world!"
  end
end
