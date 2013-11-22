require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'


class SQLObject < MassObject

  extend(Searchable)
  extend(Associatable)

  def self.set_table_name(table_name)
    @table_name = table_name.underscore

  end

  def self.table_name
    @table_name
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{self.table_name}
    SQL

    column_names = rows.first.keys
    my_attr_accessible(*column_names)

    parse_all(rows)
  end

  def self.find(id)
    attributes = DBConnection.execute(<<-SQL, id).first
    SELECT *
    FROM #{self.table_name}
    WHERE id = ?
    SQL

    new(attributes)
  end

  def create
    column_names = self.class.attributes.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO #{self.class.table_name}
    (#{column_names})
    VALUES
    (#{['?']*10.join(', ')})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    column_names = self.class.attributes
    set_lines = column_names.map do |column_name|
      "#{column_name} = ?"
    end.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE #{self.class.table_name}
    SET #{set_lines}
    WHERE id = ?
    SQL

    end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  private

  def attribute_values
    attribute_names = self.class.attributes
    values = attribute_names.map do |attribute|
      self.send(attribute)
    end
    values
  end

end
