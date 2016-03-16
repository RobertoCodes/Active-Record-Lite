require 'active_support/inflector'

class SQLObject

  def self.columns
      if @columns
        return @columns
      else
        query_result = DBConnection.execute2(<<-SQL)
          SELECT
            *
          FROM
            #{self.table_name}
          LIMIT
            0
          SQL

        @columns = query_result.first.map{|column| column.to_sym}
      end
  end

  def self.finalize!
    columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end
      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

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

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name.to_sym
      if !self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      else
        send(attr_name.to_s + "=", value)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

end
