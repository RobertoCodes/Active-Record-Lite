require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options[:foreign_key] ? @foreign_key = options[:foreign_key] : @foreign_key = (name.to_s.underscore + "_id").to_sym
    options[:primary_key] ? @primary_key = options[:primary_key] : @primary_key = :id
    options[:class_name] ? @class_name = options[:class_name] : @class_name = name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options[:foreign_key] ? @foreign_key = options[:foreign_key] : @foreign_key = (self_class_name.to_s.underscore + "_id").to_sym
    options[:primary_key] ? @primary_key = options[:primary_key] : @primary_key = :id
    options[:class_name] ? @class_name = options[:class_name] : @class_name = name.to_s.singularize.camelcase
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      foreign_key = self.send(options.foreign_key)
      options.model_class.where({options.primary_key => foreign_key}).first
    end

    assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      primary_key = self.send(options.primary_key)
      options.model_class.where({options.foreign_key => primary_key})
    end
  end

  def assoc_options
    @options ||= {}
  end

end

class SQLObject
  extend Associatable
end
