require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    results = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    results[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method "#{column}" do
        attributes[column]
      end
      define_method "#{column}=" do |x|
        attributes[column] = x
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= name.tableize
  end

  def self.all
    results = DBConnection.execute2(<<-SQL)
      SELECT #{table_name}.*
      FROM #{table_name}
    SQL

    results = results.drop(1)
    results = parse_all(results)
  end

  def self.parse_all(results)
    results = results.map do |result|
      result = Hash[result.map{|(k,v)| [k.to_sym,v]}]
    end
    results = results.map do |result|
      self.new(result)
    end
    results
  end

  def self.find(id)
    self.all.find { |obj| obj.id == id }
  end

  def initialize(params = {})
    params.each do |key, val|
      raise "unknown attribute '#{key.to_s}'" if !self.class.columns.include?(key)
      attributes[key] = val
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    col_names = self.class.columns[1..-1].join(",")
    question_marks = []
    self.class.columns[1..-1].length.times do
      question_marks << "?"
    end

    values = attribute_values

    results = DBConnection.execute2(<<-SQL, values)
      INSERT INTO #{self.class.table_name} (#{col_names})
      VALUES (#{question_marks.join(",")})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns[1..-1].join(" = ?, ")
    values = attribute_values.drop(1)

    results = DBConnection.execute2(<<-SQL, values, self.id)
      UPDATE #{self.class.table_name}
      SET #{col_names} = ?
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
