class ActiveRecord::Base
  class << self 
    def has_tableless(*tableless_models)
      tableless_models.each do |tableless_model|
        class_name = tableless_model.class == Hash ? tableless_model.collect{|k,v| k}.first.to_sym : tableless_model
        class_type = tableless_model.class == Hash ? tableless_model.collect{|k,v| v}.last : tableless_model.to_s.classify.constantize
  
        class_eval do
          default_value_for class_name => class_type.new 
          serialize class_name, Hashie::Mash

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

