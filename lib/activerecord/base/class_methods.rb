module Base
  module ClassMethods
    def default_value_for(properties)
      properties.each do |property, default_value|
        unless method_defined? "after_initialize_with_default_value_for_#{property.to_s}"

          unless method_defined? "after_initialize"
            define_method "after_initialize" do |*args|
            end
          end

          define_method "after_initialize_with_default_value_for_#{property.to_s}" do |*args| 
            send("after_initialize_without_default_value_for_#{property.to_s}", *args)
            return unless new_record? 
            return unless self.respond_to?(property.to_sym)

            self.send("#{property.to_s}=".to_sym, self.send(property.to_sym) || default_value)    
          end

          alias_method_chain "after_initialize", "default_value_for_#{property.to_s}"
        end
      end
    end


    def has_tableless(*tableless_models)
      tableless_models.each do |tableless_model|
        class_name = tableless_model.class == Hash ? tableless_model.collect{|k,v| k}.first.to_sym : tableless_model
        class_type = tableless_model.class == Hash ? tableless_model.collect{|k,v| v}.last : tableless_model.to_s.classify.constantize

        class_eval do
          default_value_for class_name => class_type.new 
          serialize class_name, ActiveRecord::TablelessModel

          define_method class_name.to_s do
            class_type.new(read_attribute(class_name.to_sym) || {})
          end

          define_method "#{class_name.to_s}=" do |value|
            super class_type.new(value)
          end
        end
      end
    end

  end
end


# Extending ActiveRecord::Base class with a macro required by the Tableless model,
# and another one that can be used to serialize a tableless model instance into
# a parent object's column

ActiveRecord::Base.extend Base::ClassMethods
