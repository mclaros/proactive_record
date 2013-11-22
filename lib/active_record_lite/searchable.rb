require_relative './db_connection'

module Searchable
  def where(params)
  	columns = params.keys
  	values = params.values

  	where_lines = columns.map do |column|
  		"#{column} = ?"
  	end.join(" AND ")

  	matching_hashes = DBConnection.execute(<<-SQL, *values)
  	SELECT *
  	FROM #{self.table_name}
  	WHERE
  	#{where_lines}
  	SQL

  	parse_all(matching_hashes)
  end
end