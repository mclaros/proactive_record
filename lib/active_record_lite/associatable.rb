require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  attr_reader :other_class_name, :foreign_key, :primary_key

  def initialize(name, params)
    @other_class_name = ( params[:class_name] ||
      name.to_s.split('_').map(&:capitalize).join('') )
    @foreign_key = params[:primary_key] || "#{name}_id"
    @primary_key = params[:primary_key] || 'id'
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_reader :other_class_name, :foreign_key, :primary_key
  def initialize(name, params, self_class)
      @other_class_name = (params[:class_name] ||
        name.to_s.singularize.split('_').map(&:capitalize).join('') )
      @foreign_key = params[:foreign_key] || ( self_class.underscore + '_id' )
      @primary_key = params[:primary_key] || 'id'
  end

  def type
  end
end

module Associatable

  def assoc_params
    @assoc_params
  end

  def belongs_to(name, params = {})
    params = BelongsToAssocParams.new(name, params)

    if @assoc_params
      @assoc_params[name] = params
    else
      @assoc_params = {name => params}
    end

    define_method(name) do

      other_table = params.other_table
      other_class = params.other_class
      foreign_key = params.foreign_key
      primary_key = params.primary_key.to_s

      query = <<-SQL

      SELECT *
      FROM #{other_table}
      WHERE
        #{primary_key} = ?
      SQL

      #Need to know name of self's foreign key to other_class
      results = DBConnection.execute(query, self.send(foreign_key))

      other_class.parse_all(results).first
   end
  end

  def has_many(name, params = {})
    params = HasManyAssocParams.new(name, params, self.class)
    define_method(name) do
      other_table = params.other_table
      other_class = params.other_class
      foreign_key = params.foreign_key
      primary_key = params.primary_key.to_s


      query = <<-SQL
      SELECT *
      FROM #{other_table}
      WHERE
        #{foreign_key} = ?
      SQL

      results = DBConnection.execute(query, self.send(primary_key))
      puts "--------\nHAS_MANY parsed results: #{other_class.parse_all(results).inspect}\n-----------"
      other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)

    define_method(name) do

      #DEBUG
      puts "\nself is #{self.inspect}"
      puts "self methods are: #{self.methods.to_a.inspect}"
      puts "\nself.class is #{self.class.inspect}"
      puts "\nself.class.assoc_params is #{self.class.assoc_params.inspect}"
      puts "\n\n"
      #END DEBUG

      assoc1_params = self.class.assoc_params[assoc1]
      assoc2_params = assoc1_params.other_class.assoc_params[assoc2]

      puts "------\narguments are: assoc1 = #{assoc1}, assoc2 = #{assoc2}"
      puts "------\nassoc1_params: #{assoc1_params.inspect} of class: #{assoc1_params.class.inspect}"
      puts "------\nassoc2_params: #{assoc2_params.inspect} of class: #{assoc2_params.class.inspect}"
      puts "self.id is: #{self.id}"
      puts "\n\n"

      query = <<-SQL
      SELECT *
      FROM
        #{assoc1_params.other_table} JOIN
        #{assoc2_params.other_table}
          ON #{assoc1_params.primary_key} = #{assoc2_params.foreign_key}
      WHERE
        owner_id = ?
      SQL

      puts "\nquery is:\n#{query}\n\n"

      results = DBConnection.execute(query, assoc1_params.foreign_key)

    end
  end
end
