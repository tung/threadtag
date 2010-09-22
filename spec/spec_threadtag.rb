ENV['RACK_ENV'] = 'test'
require 'threadtag'

require 'bacon'
require 'rack/test'

class Bacon::Context
  include Rack::Test::Methods
end

describe "The ThreadTag App" do
  def app
    ThreadTag.set :migrations_log, File.open('/dev/null', 'wb')
    ThreadTag
  end

  before do
    app.nuke_database! rescue nil
    app.migrate
  end

  it "responds to /" do
    get '/'
    last_response.should.be.ok
  end

  it "says hello world" do
    get '/hi'
    last_response.should.be.ok
    last_response.body.should.equal "Hello world!"
  end
end
