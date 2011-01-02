require "validatable"
require File.expand_path(File.join(File.dirname(__FILE__), "activerecord/base/class_methods"))

Dir[File.join(File.dirname(__FILE__), "tableless_model/*rb")].each {|f| require File.expand_path(f)}

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

  end
end

ActiveRecord::TablelessModel.extend   Tableless::ClassMethods
ActiveRecord::TablelessModel.include  Tableless::InstanceMethods
