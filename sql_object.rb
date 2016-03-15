require 'active_support/inflector'

class SQLObject

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name
      return @table_name
    else
      self.to_s.tableize
    end
  end

end
