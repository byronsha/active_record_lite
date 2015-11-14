require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = []
    params.each do |key, val|
      where_line << "#{key} = ?"
    end
    
    values = params.values

    results = DBConnection.execute2(<<-SQL, values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_line.join(" AND ")}
    SQL
    parse_all(results.drop(1))
  end
end

class SQLObject
  extend Searchable
end
