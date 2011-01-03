require "rubygems"
require "active_record"
require "lib/tableless_model"
require 'minitest/autorun'

class TestTablelessModel < ActiveRecord::TablelessModel 
end


describe TestTablelessModel do
  it "has the accessor 'attributes', originally an empty hash" do
    TestTablelessModel.must_respond_to("attributes")
    TestTablelessModel.attributes.must_be_kind_of Hash
    TestTablelessModel.attributes.must_be_empty
  end
  
  it "responds to 'attribute'" do
    TestTablelessModel.must_respond_to "attribute"
  end

  it "responds to 'attribute', 'cast'" do
    TestTablelessModel.must_respond_to "attribute"
    TestTablelessModel.must_respond_to "cast"
  end

  describe "'attribute' macro" do
    before do
      TestTablelessModel.class_eval do
        attribute :test_attribute
      end
    end
    
    it "adds a key-value pair to the attributes accessor" do
      TestTablelessModel.attributes.wont_be_empty
      TestTablelessModel.attributes.key?("test_attribute").must_equal true, "An attribute named 'test_attribute' should have been defined"
    end
  end

  describe "An instance of TablelessModel" do
    before do
      TestTablelessModel.class_eval do
        attribute :test_attribute
      end
    end

    it "tries to enforce type casting if a type has been specified for an attribute" do

      test_values = [ "test", 1234, true, "1234.12", "2011-01-02 15:23" ]
      
      [ :string, :integer, :float, :decimal, :time, :date, :datetime, :boolean ].each do |type|

        # temporarily changing type
        TestTablelessModel.attributes["test_attribute"][:type] = type

        instance = TestTablelessModel.new
        
        # instance.must_respond_to "test_attribute", "Getter for test_attribute should have been defined"
        # instance.must_respond_to "test_attribute=", "Setter for test_attribute should have been defined"

        type_name = case type
        when :datetime then :date_time
        when :decimal then :big_decimal
        else type
        end


        # excluding some test values that would always faild depending on the type
        exclude_test_values = case type
        when :decimal then [ "test", true ]
        when :time then [ 1234, true ]
        when :date then [ "test", 1234, true, "1234.12" ]
        when :datetime then [ "test", 1234, true ]
        else []
        end


        (test_values - exclude_test_values).each do |value|

          instance.test_attribute = value

          if type == :boolean
            [true, false].include?(instance.test_attribute).must_equal true, "Expected #{instance.test_attribute.inspect} to be boolean, not #{type.class}"
          else
            instance.test_attribute.must_be_kind_of type_name.to_s.classify.constantize
          end
          
        end

      end
    end
  end

end