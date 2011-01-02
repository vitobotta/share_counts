class ActiveRecord::Base
  class << self
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
  end
end