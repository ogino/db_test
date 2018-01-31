require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require File.expand_path(File.dirname(__FILE__) + '/utils/commons.rb')
require File.expand_path(File.dirname(__FILE__) + '/utils/configure.rb')
require File.expand_path(File.dirname(__FILE__) + '/databases/test_dao.rb')

class Server < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  set :public_folder, File.expand_path(File.dirname(__FILE__) + '/../public')

  set :show_exceptions, false

  set :raise_errors, false

  get '/' do
    init_logger unless defined?($logger)
    begin
      result = TestDao.new.find
      raise 'ILLEGAL' if result.empty?
      slim :index, :layout => false, locals: {
          result: 'OK, value is ' << result.to_s
      }
    rescue => e
      $logger.error '[%s](%d) %s' % [File.basename(__FILE__), __LINE__, e.message]
      $logger.error get_stack_trace(e)
      raise e.message
    end
  end

  after do
    cache_control :no_cache
  end

end