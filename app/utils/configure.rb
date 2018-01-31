# coding:UTF-8

require 'rubygems'
require 'jdbc/mysql'
require 'java'
require 'logger'
require 'yaml'

require File.expand_path File.dirname(__FILE__) + '/commons.rb'

def init_configurations
  begin
    Jdbc::MySQL.load_driver
    $config = YAML.load_file File.expand_path(File.dirname(__FILE__) + '/../../conf/config.yaml')
    raise Exception.new 'configurations invalid' if $config.nil?
    init_logger if !defined?($logger) || !$logger.nil?
    $logger.debug '[%s](%d) config = %s' % [File.basename(__FILE__), __LINE__, $config.to_s]
    create_connections
  rescue => e
    if defined?($logger) && !$logger.nil?
      $logger.error '[%s](%d) %s' % [File.basename(__FILE__), __LINE__, e.message]
      $logger.error get_stack_trace(e)
    end
    raise Exception.new e.message
  end
end

def init_logger
  if !defined?($logger) || $logger.nil?
    begin
      unless defined?($use_jetty) && defined?($debug)
        config = YAML.load_file File.expand_path(File.dirname(__FILE__) + '/../../conf/config.yaml')
        raise Exception.new 'configurations invalid' if config.nil?
      end
      home_dir = File.dirname(File.expand_path(File.dirname(__FILE__) + '/../'))
      path = File.expand_path(home_dir + '/logs/db_test.log')
      file = File.open(path, File::WRONLY | File::APPEND | File::CREAT)
      $logger = Logger.new file, 'daily'
      $logger.level = Logger::DEBUG
      $logger.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity} #{msg}\n"
      end
    rescue => e
      raise Exception.new e.message
    end
  end
end

def complete_close(conn)
  if defined?(conn) && !conn.nil? && conn.is_a?(java.sql.Connection)
    begin
      conn.close
    rescue => e
      if defined?($logger) && !$logger.nil?
        $logger.error '[%s](%d) %s' % [File.basename(__FILE__), __LINE__, e.message]
        $logger.error get_stack_trace(e)
      end
    end
  end
end

def create_connections
  unless is_valid_connection $connection
    complete_close $connection
    $connection = create_connection $config['database']
  end
end

def create_connection(config)
  Jdbc::MySQL.load_driver
  raise Exception.new 'config = %s, NOT valid configuration' % config unless defined?(config) && config.is_a?(Hash) && !config.empty?
  raise Exception.new 'Must do firstly, initialize configuration' if !defined?($logger) || $logger.nil?
  $logger.debug '[%s](%d) config = %s' % [File.basename(__FILE__), __LINE__, config.to_s]
  jdbc_url = create_jdbc_url config
  raise Exception.new 'jdbc_url invalid' if jdbc_url.nil?
  $logger.debug '[%s](%d) jdbc_url = %s' % [File.basename(__FILE__), __LINE__, jdbc_url]
  $logger.debug '[%s](%d) config: user = %s, password = %s'% [File.basename(__FILE__), __LINE__, config['user'], config['password']]
  conn = java.sql.DriverManager.get_connection jdbc_url, config['user'], config['password']
  conn.set_auto_commit true
  conn
end