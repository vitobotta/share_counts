module Tableless
  module InstanceMethods

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

      self.class.attributes.each_pair {|attribute_name, options| self.send("#{attribute_name}=", options[:default])}
      init_attributes.each_pair {|k,v| self.send("#{k}=", v)} if init_attributes
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
      
      return_value = super(attribute_name.to_s, self.class.cast(attribute_name, value))

      if self.__owner_object 
        # This makes the tableless model compatible with partial_updates:
        # whenever a property in the tableless model is changed, we force the parent/owner object to a changed state
        # by updating it with a new, updated instance of the tableless model
        self.__owner_object.send "#{self.__serialized_attribute.to_s}=".to_sym, self
      end

      return_value
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
      "<##{self.class.to_s}" << self.keys.sort.inject(""){|result, k| result << " #{k}=#{self[k].inspect}"; result }  << ">"
    end
    
    
    # 
    # 
    # Since the object should only allow the defined attributes
    # merging is forbidden
    # 
    def merge(hash)
      raise NoMethodError
    end

  end
end
