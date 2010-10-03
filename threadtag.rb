require 'rubygems'
require 'bundler/setup'

require 'haml'
require 'json'
require 'sinatra/base'
require 'sinatra/sequel'

class ThreadTag < Sinatra::Base
  register Sinatra::SequelExtension

  def self.migrate
    migration 'create threadtag table' do
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
    migration 'add vote columns to threadtag table' do
      database.alter_table :threadtag do
        add_column :upvote, Integer, :default => 0
        add_column :downvote, Integer, :default => 0
      end
    end
  end
  migrate

  def self.nuke_database!
    database.drop_table :migrations
    database.drop_table :threadtag
  end

  def sanitize_tag(tag)
    tag.downcase
  end

  before do
    @tbl = database[:threadtag]
  end

  get '/' do
    haml :index
  end

  get '/tags-for/:board/:thread' do
    # JSON response == [
    #   {
    #     tag: 'tag-name',
    #     up: sum-of-upvotes,
    #     down: sum-of-downvotes
    #   },
    #   ...]
    response['Content-Type'] = 'application/json'
    tag_rows = @tbl.
      where(:board => params[:board], :thread => params[:thread]).
      group(:tag).
      select(:tag, :SUM.sql_function(:upvote), :SUM.sql_function(:downvote))
    tags = []
    tag_rows.each do |tag_row|
      tags << {
        'tag' => tag_row[:tag],
        'up' => tag_row[:"SUM(`upvote`)"],
        'down' => tag_row[:"SUM(`downvote`)"]
      }
    end
    JSON.generate tags
  end

  post '/upvote-tag/:board/:thread/:tag' do
    board = params[:board]
    thread = params[:thread]
    tag = sanitize_tag(params[:tag])
    ip = request.ip
    updated_at = Time.now
    if @tbl.
        where(:board => board, :thread => thread, :tag => tag, :ip => ip).
        update(:upvote => 1, :downvote => 0, :updated_at => updated_at) < 1
      @tbl.insert(:board => board, :thread => thread, :tag => tag, :ip => ip, :upvote => 1, :updated_at => updated_at)
    end
  end

  post '/downvote-tag/:board/:thread/:tag' do
    board = params[:board]
    thread = params[:thread]
    tag = sanitize_tag(params[:tag])
    ip = request.ip
    updated_at = Time.now
    if @tbl.
        where(:board => board, :thread => thread, :tag => tag, :ip => ip).
        update(:upvote => 0, :downvote => 1, :updated_at => updated_at) < 1
      @tbl.insert(:board => board, :thread => thread, :tag => tag, :ip => ip, :downvote => 1, :updated_at => updated_at)
    end
  end
end
