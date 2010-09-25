ENV['RACK_ENV'] = 'test'
require 'threadtag'

require 'bacon'
require 'rack/test'

class Bacon::Context
  include Rack::Test::Methods
end

describe 'The ThreadTag App' do
  def app
    ThreadTag.set :migrations_log, File.open('/dev/null', 'wb')
    ThreadTag
  end

  before do
    app.nuke_database! rescue nil
    app.migrate
    @db = app.database
  end

  it 'should respond to /' do
    get '/'
    last_response.should.be.ok
  end

  it 'should list tags for a thread' do
    @db[:threadtag].insert(:board => 'a', :thread => 1, :tag => 'tag1', :ip => '127.0.0.1', :updated_at => Time.now)
    @db[:threadtag].insert(:board => 'a', :thread => 1, :tag => 'tag2', :ip => '127.0.0.1', :updated_at => Time.now)
    @db[:threadtag].insert(:board => 'a', :thread => 1, :tag => 'tag3', :ip => '127.0.0.1', :updated_at => Time.now)

    get '/tags-for/a/1'
    last_response.body.should.include 'tag1'
    last_response.body.should.include 'tag2'
    last_response.body.should.include 'tag3'
  end

  it 'should respond in JSON' do
    @db[:threadtag].insert(:board => 'a', :thread => 1, :tag => 'tag1', :ip => '127.0.0.1', :updated_at => Time.now)

    get '/tags-for/a/1'
    last_response['Content-Type'].should.equal 'application/json'

    json_response = JSON.parse(last_response.body)
    json_response[0]['tag'].should.equal 'tag1'
  end
end
