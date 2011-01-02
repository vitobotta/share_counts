require "validatable"
require File.expand_path(File.join(File.dirname(__FILE__), "activerecord/base/class_methods"))


# TODO: add support for associations

module ActiveRecord
  
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
      self.attributes[attribute_name] = options
      
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

      self.class.attributes.each_pair {|attribute_name, options| self[attribute_name] = options[:default]}
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
      self.class.cast(attribute_name, super(attribute_name.to_s))
    end
    

    # 
    # 
    # Overriding setter for the underlying hash keys
    # so that only the defined attributes can be set
    # 
    def []=(attribute_name, value)
      raise NoMethodError, "The attribute #{attribute_name} is undefined" unless self.class.attributes.has_key? attribute_name.to_s
      super attribute_name.to_s, self.class.cast(attribute_name, value)
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
    
    
    
    # 
    # 
    # If a data type has been specified for an attribute, its value
    # will be converted accordingly (if necessary) when getting or setting it
    # 
    # 
    def self.cast(attribute_name, value)
      return nil if value.nil?

      type = self.attributes[attribute_name.to_s][:type]
      
      return value if type.nil?
      
      begin
        case type
          when :string    then (value.is_a?(String) ? value : String(value))
          when :integer   then (value.is_a?(Integer) ? value : Integer(value))
          when :float     then (value.is_a?(Float) ? value : Float(value))
          when :decimal   then (value.is_a?(Float) ? value : Float(value))
          when :time      then (value.is_a?(Time) ? value : Time.parse(value))
          when :date      then (value.is_a?(Date) ? value : Date.parse(value))
          when :datetime  then (value.is_a?(DateTime) ? value : DateTime.parse(value))
          when :boolean   then (value == true || value == 1 || value.to_s =~ /^(true|1)$/i)
          else value
        end
      rescue Exception => e
        raise StandardError, "Invalid value '#{value.inspect}' for attribute #{attribute_name} - expected data type is #{type} but value is a #{value.class} (Exception details: #{e})"    
        value
      end
    end
    

  end
  
end

