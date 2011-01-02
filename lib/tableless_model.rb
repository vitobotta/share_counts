require "validatable"
require File.expand_path(File.join(File.dirname(__FILE__), "tableless_model/class_methods"))

module ActiveRecord
  
  class Base
    extend TablelessModel::ClassMethods
  end
  
  class TablelessModel < Hashie::Mash
    include ::Validatable

    @@default_values = {}

    def initialize(*args)
      super *args

      self.merge!(@@default_values[self.class.name])
      self.merge!(args.size != 0 && args.first.is_a?(Hash) ? args.first : {})
    end

    def self.has(columns)
      @@default_values[self.name] = { } unless @@default_values.has_key?(self.name)

      columns.each do |name, options|
        type          = options[:type] || :string
        default_value = type_cast(type, options[:default])
        association   = options[:references]

        self.send(:define_method, name, proc{ self[name].nil? ? default_value : TablelessModel.type_cast(type, self[name]);  })
        self.send(:define_method, "#{name}=", proc{|value| self[name] = TablelessModel.type_cast(type, value) })

        @@default_values[self.name][name] = default_value

        unless association.nil?
          if association.is_a?(Hash)
            association_name  = type == :array ? association.collect{|k,v| k}.first.pluralize : association.collect{|k,v| k}.first
            association_class = association.collect{|k,v| v}.first
          else
            association_class = association
            association_name  = type == :array ? association.name.underscore.pluralize : association.name.underscore
          end

          define_method association_name.to_s do
            association_class.find(self.send(name))
          end
        end

      end
    end

    def self.type_cast(type, value)
      return nil if value.nil?
      case type
        when :string    then value
        when :text      then value
        when :integer   then value.to_i rescue value ? 1 : 0
        when :float     then value.to_f
        when :decimal   then value_to_decimal(value)
        when :datetime  then string_to_time(value)
        when :timestamp then string_to_time(value)
        when :time      then string_to_dummy_time(value)
        when :date      then string_to_date(value)
        when :binary    then binary_to_string(value)
        when :boolean   then value_to_boolean(value)
        else value
      end
    end

    # ==========================================================================================================================================
    #  Type casting methods similar to those used by ActiveRecord to ensure data types
    # ==========================================================================================================================================
    def self.value_to_boolean(value)
      if value.is_a?(String) && value.blank?
        nil
      else
        [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set.include?(value)
      end
    end

    # convert something to a BigDecimal
    def self.value_to_decimal(value)
      # Using .class is faster than .is_a? and
      # subclasses of BigDecimal will be handled
      # in the else clause
      if value.class == BigDecimal
        value
      elsif value.respond_to?(:to_d)
        value.to_d
      else
        value.to_s.to_d
      end
    end


    def self.string_to_binary(value)
      value
    end

    # Used to convert from BLOBs to Strings
    def self.binary_to_string(value)
      value
    end

    def self.string_to_date(string)
      return string unless string.is_a?(String)
      return nil if string.empty?

      ActiveRecord::ConnectionAdapters::Column.fast_string_to_date(string) || ActiveRecord::ConnectionAdapters::Column.fallback_string_to_date(string)
    end

    def self.string_to_time(string)
      return string unless string.is_a?(String)
      return nil if string.empty?

      ActiveRecord::ConnectionAdapters::Column.fast_string_to_time(string) || ActiveRecord::ConnectionAdapters::Column.fallback_string_to_time(string)
    end

    def self.string_to_dummy_time(string)
      return string unless string.is_a?(String)
      return nil if string.empty?

      ActiveRecord::ConnectionAdapters::Column.string_to_time "2000-01-01 #{string}"
    end

  end
end


