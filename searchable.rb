require_relative 'db_connection'
require_relative 'sql_object'

module Searchable

  def where(params)
    where_array = []

    params.keys.each do |param|
      where_array << "#{param} = ?"
    end

    where_string = where_array.join(" AND ")

    results = DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_string}
      SQL

    parse_all(results)

  end

end

class SQLObject
  extend Searchable
end
