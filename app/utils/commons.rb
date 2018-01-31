# coding:UTF-8

require 'rubygems'
require 'date'
require 'java'

java_import 'java.sql.Connection'

def create_jdbc_url(config)
  return nil if config.nil?
  url = 'jdbc:mysql:'
  if config['loadbalance']
    url << 'loadbalance://'
    count = 0
    for ip in config['host'].split(',') do
      $logger.debug('count = ' + count.to_s + ', ip = ' + ip)
      url += ',' if 0 < count
      url += ip + ':' + config['port'].to_s
      count += 1
    end
    url << '/' + config['schema'] + '?loadBalanceBlacklistTimeout=5000&roundRobinLoadBalance=true&'
  else
    url << '//' + config['host'] + ':' + config['port'].to_s + '/' + config['schema'] + '?'
  end
  unless config['ssl']
	url << 'useSSL=true&requireSSL=true&verifyServerCertificate=false&'
  else
    url << 'useSSL=false&'
  end
  url << 'useUnicode=true&characterEncoding=UTF-8&autoReconnectForPools=true&reconnectAtTxEnd=true&autoReconnect=true&zeroDateTimeBehavior=convertToNull'
end

def get_stack_trace(e)
  return '' if e.nil? || e.backtrace.nil?
  trace = "\n"
  e.backtrace.each {|line|
    trace << '    at '
    trace << line
    trace << "\n"
  }
  trace
end

def is_valid_connection(conn)
  unless defined?(conn)
    return false
  end
  if conn.nil?
    return false
  end
  unless conn.is_a?(java.sql.Connection)
    return false
  end
  init_logger if !defined?($logger) || !$logger.nil?
  if conn.is_closed
    conn.close
    $logger.debug '[%s](%d) conn = %s, Closed' % [File.basename(__FILE__), __LINE__, conn.to_s]
    return false
  end
  begin
    stmt = conn.create_statement
    stmt.set_fetch_size 1
    stmt.execute_query 'SELECT 1 FROM DUAL'
  rescue => e
    conn.close
    $logger.debug '[%s](%d) conn = %s, Closed' % [File.basename(__FILE__), __LINE__, conn.to_s]
    $logger.debug '[%s](%d) %s' % [File.basename(__FILE__), __LINE__, e.message]
    $logger.debug get_stack_trace(e)
    return false
  end
  true
end
