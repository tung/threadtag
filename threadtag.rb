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
  end
  migrate

  def self.nuke_database!
    database.drop_table :migrations
    database.drop_table :threadtag
  end

  get '/' do
    haml :index
  end

  get '/tags-for/:board/:thread' do
    # JSON response == [{tag: 'tag-name'}, ...]
    response['Content-Type'] = 'application/json'
    tag_rows = database[:threadtag].select(:tag).where(:board => params[:board], :thread => params[:thread])
    tags = []
    tag_rows.each do |tag_row|
      tags << { 'tag' => tag_row[:tag] }
    end
    JSON.generate tags
  end
end
