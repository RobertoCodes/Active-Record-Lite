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
      define_method(column.to_s) do
        attributes[column]
      end
      define_method(column.to_s + "=") do |value|
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

  def self.all
    parse_all(DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      SQL
      )
  end

  def self.parse_all(results)
    results.map{|attr_hash| new(attr_hash)}
  end

  def self.find(id)
    query_result = (DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
      SQL
      )
    if query_result.first == nil
      return nil
    else
      new(query_result.first)
    end
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if !self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      else
        send(attr_name.to_s + "=", value)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      send(column)
    end
  end

  def insert
    column_names = "(" + self.class.columns.join(",") + ")"
    question_mark_string = "(" + (["?"] * self.class.columns.count).join(",") + ")"
    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name + column_names}
      VALUES
        #{question_mark_string}
      SQL
    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    set_string = self.class.columns.map{|attribute| "#{attribute} = ?"}.join(",")
    DBConnection.execute(<<-SQL, attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_string}
      WHERE
        id = ?
      SQL
  end

  def save
    self.id == nil ? insert : update
  end

end
