require "validatable"
require File.expand_path(File.join(File.dirname(__FILE__), "tableless_model/class_methods"))


module ActiveRecord
  
  # Extending ActiveRecord::Base class with a macro required by the Tableless model,
  # and another one that can be used to serialize a tableless model instance into
  # a parent object's column

  Base.extend TablelessModel::ClassMethods
  
    


  # TablelessModel class is basically an Hash with method-like keys that must be defined in advance
  # as for an ActiveRecord model, but without a table. Trying to set new keys not defined at class level
  # result in NoMethodError raised 

  class TablelessModel < Hash

    # 
    # 
    # Exposes an accessors that will store the names of the attributes defined for the Tableless model,
    # and their default values
    # This accessor is an instance of Set defined in the inheriting class (see self.inherited)
    # 
    # 
    class << self
      attr_reader :attributes
    end


    # 
    # 
    # Macro to define an attribute of the Tableless model.
    # To be used as follows in a tableless model:
    # 
    #     class Example < ActiveRecord::TablelessModel
    # 
    #       attribute :name,    :type => :string
    #       attribute :active,  :type => :boolean, :default => true
    # 
    #     end
    # 
    # 
    def self.attribute(name, options = {})
      # Stringifies all keys... uses a little more memory but it's a bit easier to handle keys internally...
      attribute_name = name.to_s
      
      # Defining the new attribute for the tableless model
      self.attributes[attribute_name] = options[:default] 
      
      # Defining method-like getter and setter for the new attribute
      # so it can be used like a regular object's property
      class_eval %Q{
        def #{attribute_name}
          self["#{attribute_name}"]
        end
      
        def #{attribute_name}=(value)
          self["#{attribute_name}"] = value
        end
      }
    end
    
    
    # 
    # 
    # Initialises @attributes in the context of the class inheriting from the Tableless model
    # 
    def self.inherited(klass)
      super
      (@subclasses ||= Set.new) << klass
      klass.instance_variable_set("@attributes",  Hash.new)
    end
    
    
    # 
    # 
    # On initialising an instance of a tableless model,
    # sets the default values for all the attributes defined.
    # Optionally, initialises the tableless model with the values 
    # specified as arguments, instead, overriding the default values
    # 
    # 
    def initialize(init_attributes = {}, &block)
      super &block

      self.class.attributes.each_pair {|k,v | self[k] = v}
      init_attributes.each_pair {|k,v| self[k] = v} if init_attributes
    end


    # 
    # 
    # Returns true if the method name specified corresponds 
    # to the key of an attribute defined for the tableless model
    # 
    # 
    def respond_to?(method_name)
      key?(method_name) ? true : super
    end
    

    # 
    # 
    # Overriding getter for the underlying hash keys
    # so that only the defined attributes can be read 
    # 
    def [](attribute_name)
      raise NoMethodError, "The attribute #{attribute_name} is undefined" unless self.class.attributes.has_key? attribute_name.to_s
      super attribute_name.to_s
    end
    

    # 
    # 
    # Overriding setter for the underlying hash keys
    # so that only the defined attributes can be set
    # 
    def []=(attribute_name, value)
      raise NoMethodError, "The attribute #{attribute_name} is undefined" unless self.class.attributes.has_key? attribute_name.to_s
      super attribute_name.to_s, value
    end
    
    
    # 
    # 
    # The Hash object displays inspect information in the format
    # 
    #   "{:a=>1, :b=>2}"
    # 
    # to make the tableless model look a bit more like regular models,
    # it shows instead the inspect information in this format:
    # 
    #   "<#MyTablelessModel a=1 b=2>"
    # 
    def inspect
      "<##{self.class.to_s}" << self.keys.inject(""){|result, k| result << " #{k}=#{self[k].inspect}"; result }  << ">"
    end
    
  end
  
end


# module ActiveRecord
#   
#   
#   class TablelessModel < Hashie::Mash
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
