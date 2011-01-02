require "validatable"
require File.expand_path(File.join(File.dirname(__FILE__), "tableless_model/class_methods"))


module ActiveRecord
  
  Base.extend TablelessModel::ClassMethods
  
  class TablelessModel < Hash
    
    alias_method :to_s, :inspect
    
    class << self
      attr_reader :attribute_names, :default_values
    end

    def self.attribute(name, options = {})
      attribute_name = name.to_s
      
      self.attribute_names << attribute_name
      self.default_values[attribute_name] = options[:default] 
      
      class_eval %Q{
        def #{attribute_name}
          self["#{attribute_name}"]
        end
      
        def #{attribute_name}=(value)
          self["#{attribute_name}"] = value
        end
      }
    end
    
    def self.inherited(klass)
      super
      
      (@subclasses ||= Set.new) << klass
      
      klass.instance_variable_set("@attribute_names", Set.new)
      klass.instance_variable_set("@default_values",  Hash.new)
    end
    
    
    
    def initialize(init_attributes = {}, &block)
      super &block

      self.class.attribute_names.each {|k| self[k] = self.class.default_values[k]}
      init_attributes.each_pair {|k,v| puts k; self[k] = v} if init_attributes
    end

    def id
      self["id"] || super
    end
    
    def respond_to?(method_name)
      key?(method_name) ? true : super
    end
    
    
    def [](attribute_name)
      raise NoMethodError, "The attribute #{attribute_name} is undefined" unless self.class.attribute_names.include? attribute_name.to_s
      super attribute_name.to_s
    end
    
    def []=(attribute_name, value)
      raise NoMethodError, "The attribute #{attribute_name} is undefined" unless self.class.attribute_names.include? attribute_name.to_s
      super attribute_name.to_s, value
    end
    
    
    def inspect
      "<##{self.class.to_s}" << self.keys.inject(""){|result, k| result << " #{k}=#{self[k].inspect}"; result }  << ">"
    end
    
  end
  
end


# module ActiveRecord
#   
#   # Extending ActiveRecord::Base class with a macro required by the Tableless model,
#   # and another one that can be used to serialize a tableless model instance into
#   # a parent object's column
#   Base.extend TablelessModel::ClassMethods
#   
#   class TablelessModel < Hashie::Mash
#     # TablelessModel class is basically an Hash which with method-like keys
#     # It currently uses Hashie::Mash for this functionality
#     # TODO: Remove dependency on Hashie::Mash
#     
#     
#     # Using the gem validatable to add validations support as for table based ActiveRecord models
#     # See http://validatable.rubyforge.org/
#     include ::Validatable
# 
#     # Hashie gem also exposes the class Hashie::Dash which works in a similar way to Hashie::Mash,
#     # plus it allows to define in advance the properties of a Mash object and also to set default values for them.
#     # However, it does not enforce the types for these properties, so I am instead using the regular Mash class
#     # and managing default values in a different way.
#     # With Dash, properties that are defined in the class declaration but have not been s
#     # @@default_values = {}
# 
#     # def initialize(*args)
#     #   super *args
#     # 
#     #   self.merge!(@@default_values[self.class.name])
#     #   self.merge!(args.size != 0 && args.first.is_a?(Hash) ? args.first : {})
#     # end
# 
#     # def self.has(columns)
#     #   @@default_values[self.name] = { } unless @@default_values.has_key?(self.name)
#     # 
#     #   columns.each do |name, options|
#     #     type          = options[:type] || :string
#     #     default_value = type_cast(type, options[:default])
#     #     association   = options[:references]
#     # 
#     #     self.send(:define_method, name, proc{ self[name].nil? ? default_value : TablelessModel.type_cast(type, self[name]);  })
#     #     self.send(:define_method, "#{name}=", proc{|value| self[name] = TablelessModel.type_cast(type, value) })
#     # 
#     #     @@default_values[self.name][name] = default_value
#     # 
#     #     unless association.nil?
#     #       if association.is_a?(Hash)
#     #         association_name  = type == :array ? association.collect{|k,v| k}.first.pluralize : association.collect{|k,v| k}.first
#     #         association_class = association.collect{|k,v| v}.first
#     #       else
#     #         association_class = association
#     #         association_name  = type == :array ? association.name.underscore.pluralize : association.name.underscore
#     #       end
#     # 
#     #       define_method association_name.to_s do
#     #         association_class.find(self.send(name))
#     #       end
#     #     end
#     # 
#     #   end
#     # end
# 
#     def self.type_cast(type, value)
#       return nil if value.nil?
#       case type
#         when :string    then value
#         when :text      then value
#         when :integer   then value.to_i rescue value ? 1 : 0
#         when :float     then value.to_f
#         when :decimal   then value_to_decimal(value)
#         when :datetime  then string_to_time(value)
#         when :timestamp then string_to_time(value)
#         when :time      then string_to_dummy_time(value)
#         when :date      then string_to_date(value)
#         when :binary    then binary_to_string(value)
#         when :boolean   then value_to_boolean(value)
#         else value
#       end
#     end
# 
#     # ==========================================================================================================================================
#     #  Type casting methods similar to those used by ActiveRecord to ensure data types
#     # ==========================================================================================================================================
#     def self.value_to_boolean(value)
#       if value.is_a?(String) && value.blank?
#         nil
#       else
#         [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set.include?(value)
#       end
#     end
# 
#     # convert something to a BigDecimal
#     def self.value_to_decimal(value)
#       # Using .class is faster than .is_a? and
#       # subclasses of BigDecimal will be handled
#       # in the else clause
#       if value.class == BigDecimal
#         value
#       elsif value.respond_to?(:to_d)
#         value.to_d
#       else
#         value.to_s.to_d
#       end
#     end
# 
# 
#     def self.string_to_binary(value)
#       value
#     end
# 
#     # Used to convert from BLOBs to Strings
#     def self.binary_to_string(value)
#       value
#     end
# 
#     def self.string_to_date(string)
#       return string unless string.is_a?(String)
#       return nil if string.empty?
# 
#       ActiveRecord::ConnectionAdapters::Column.fast_string_to_date(string) || ActiveRecord::ConnectionAdapters::Column.fallback_string_to_date(string)
#     end
# 
#     def self.string_to_time(string)
#       return string unless string.is_a?(String)
#       return nil if string.empty?
# 
#       ActiveRecord::ConnectionAdapters::Column.fast_string_to_time(string) || ActiveRecord::ConnectionAdapters::Column.fallback_string_to_time(string)
#     end
# 
#     def self.string_to_dummy_time(string)
#       return string unless string.is_a?(String)
#       return nil if string.empty?
# 
#       ActiveRecord::ConnectionAdapters::Column.string_to_time "2000-01-01 #{string}"
#     end
# 
#   end
# end
# 
# 
