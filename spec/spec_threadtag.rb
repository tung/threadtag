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
    @tbl = @db[:threadtag]
  end

  def upvote(board, thread, tag, ip)
    @tbl.insert(
      :board => board,
      :thread => thread,
      :tag => tag,
      :ip => ip,
      :upvote => 1,
      :updated_at => Time.now)
  end

  def downvote(board, thread, tag, ip)
    @tbl.insert(
      :board => board,
      :thread => thread,
      :tag => tag,
      :ip => ip,
      :downvote => 1,
      :updated_at => Time.now)
  end

  it 'should respond to /' do
    get '/'
    last_response.should.be.ok
  end

  it 'should respond in JSON' do
    upvote('a', 1, 'tag1', '127.0.0.1')

    get '/tags-for/a/1'
    last_response['Content-Type'].should.equal 'application/json'
    json_response = JSON.parse(last_response.body)
    json_response[0]['tag'].should.equal 'tag1'
  end

  it 'should list tags for a thread' do
    upvote('a', 1, 'tag1', '127.0.0.1')
    upvote('a', 1, 'tag2', '127.0.0.1')
    upvote('a', 1, 'tag3', '127.0.0.1')

    get '/tags-for/a/1'
    last_response.body.should.include 'tag1'
    last_response.body.should.include 'tag2'
    last_response.body.should.include 'tag3'
  end

  it 'should list upvotes with tags for a thread' do
    upvote('a', 1, 'plus-2-minus-1', '127.0.0.1')
    upvote('a', 1, 'plus-2-minus-1', '127.0.0.2')
    downvote('a', 1, 'plus-2-minus-1', '127.0.0.3')

    get '/tags-for/a/1'
    rsp = JSON.parse(last_response.body)
    rsp[0]['up'].should.equal 2
  end

  it 'should list downvotes with tags for a thread' do
    upvote('a', 1, 'plus-1-minus-2', '127.0.0.1')
    downvote('a', 1, 'plus-1-minus-2', '127.0.0.2')
    downvote('a', 1, 'plus-1-minus-2', '127.0.0.3')

    get '/tags-for/a/1'
    rsp = JSON.parse(last_response.body)
    rsp[0]['down'].should.equal 2
  end

  it 'should accept upvotes' do
    post '/upvote-tag/a/1/tag1'
    last_response.should.be.ok

    get '/tags-for/a/1'
    rsp = JSON.parse(last_response.body)
    rsp[0]['up'].should.equal 1
  end

  it 'should accept downvotes' do
    post '/downvote-tag/a/1/tag1'
    last_response.should.be.ok

    get '/tags-for/a/1'
    rsp = JSON.parse(last_response.body)
    rsp[0]['down'].should.equal 1
  end

  it 'should not double-count upvotes from the same IP' do
    post '/upvote-tag/a/1/tag1'
    last_response.should.be.ok
    post '/upvote-tag/a/1/tag1'
    last_response.should.be.ok

    get '/tags-for/a/1'
    rsp = JSON.parse(last_response.body)
    rsp[0]['up'].should.not.equal 2
  end

  it 'should register a downvote for a previously upvoted tag' do
    post '/upvote-tag/a/1/tag1'
    last_response.should.be.ok
    post '/downvote-tag/a/1/tag1'
    last_response.should.be.ok

    get '/tags-for/a/1'
    rsp = JSON.parse(last_response.body)
    rsp[0]['up'].should.not.equal 1
    rsp[0]['down'].should.equal 1
  end
end
