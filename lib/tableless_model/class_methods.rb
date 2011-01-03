module Tableless
  module ClassMethods

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
    def attribute(name, options = {})
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
    def inherited(klass)
      super
      (@subclasses ||= Set.new) << klass
      klass.instance_variable_set("@attributes",  Hash.new)
    end
  
  
    # 
    # 
    # If a data type has been specified for an attribute, its value
    # will be converted accordingly (if necessary) when getting or setting it
    # 
    # 
    def cast(attribute_name, value)
      return nil if value.nil?

      type = self.attributes[attribute_name.to_s][:type]
    
      return value if type.nil?
    
      begin
        case type
          when :string    then (value.is_a?(String) ? value : String(value))
          when :integer   then (value.is_a?(Integer) ? value : value.to_s.to_i)
          when :float     then (value.is_a?(Float) ? value : value.to_s.to_f)
          when :decimal   then (value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s))
          when :time      then (value.is_a?(Time) ? value : Time.parse(value))
          when :date      then (value.is_a?(Date) ? value : Date.parse(value))
          when :datetime  then (value.is_a?(DateTime) ? value : DateTime.parse(value))
          when :boolean   then (["true", "1"].include?(value.to_s))
          else value
        end
      rescue Exception => e
        raise StandardError, "Invalid value #{value.inspect} for attribute #{attribute_name} - expected data type is #{type.to_s.capitalize} but value is a #{value.class} (Exception details: #{e})"    
        value
      end
    end

  end
end

