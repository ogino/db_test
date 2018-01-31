# coding: utf-8

require 'time'

require File.expand_path(File.dirname(__FILE__) + '/../utils/configure.rb')
require File.expand_path(File.dirname(__FILE__) + '/../utils/commons.rb')

class TestDao

  def initialize
    init_configurations unless defined?($config) && !$config.nil?
    create_connections unless is_valid_connection $connection
  end

  def find
    result = {}
    begin
      sql = 'SELECT 1 FROM DUAL'
      stmt = $connection.prepare_statement sql
      stmt.set_fetch_size 1
      rs = stmt.execute_query
      rsmd = rs.get_meta_data
      if rs.next
        for i in 1...rsmd.get_column_count + 1
          column = rsmd.get_column_label i
          result[column] = rs.get_object column
        end
      end
    rescue => e
      $logger.error '[%s](%d) %s' % [File.basename(__FILE__), __LINE__, e.message]
      $logger.error get_stack_trace(e)
      raise Exception.new e.message
    ensure
      stmt.close if defined?(stmt) && !stmt.nil?
    end
    result
  end

end