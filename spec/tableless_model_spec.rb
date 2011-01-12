require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

require "active_record"
require 'minitest/autorun'

require File.expand_path(File.join(File.dirname(__FILE__), "../lib/tableless_model"))


describe "A class inheriting from ActiveRecord::TablelessModel" do
  before do
    class TestClass1 < ActiveRecord::TablelessModel
    end
  end
  
  it "has the accessor 'attributes', which is originally an empty hash" do
    TestClass1.must_respond_to("attributes")
    TestClass1.attributes.must_be_kind_of Hash
    TestClass1.attributes.must_be_empty
  end

  it "responds to 'attribute', 'cast'" do
    ["attribute", "cast"].each {|method_name| TestClass1.must_respond_to method_name }
  end
end

describe "The 'attribute' macro" do
  before do
    class TestClass < ActiveRecord::TablelessModel
      attribute :test_attribute
    end
  end

  it "adds a key-value pair to the attributes accessor" do
    TestClass.attributes.wont_be_empty
    TestClass.attributes.key?("test_attribute").must_equal true, "An attribute named 'test_attribute' should have been defined"
  end
end

describe "An instance of TablelessModel" do
  before do
    class TestClass2 < ActiveRecord::TablelessModel
      attribute :test_attribute
      attribute :test_attribute_with_default_value,           :default => "default value"
      attribute :test_attribute_with_type_and_default_value,  :default => "003xxx", :type => :integer
    end
    
    @instance = TestClass2.new
  end
  
  it "has a getter and a setter for each defined attribute" do
    [:test_attribute, :test_attribute_with_default_value, :test_attribute_with_type_and_default_value].each do |attribute_name|
      @instance.must_respond_to attribute_name,       "Getter for #{attribute_name} should have been defined"
      @instance.must_respond_to "#{attribute_name}=", "Setter for #{attribute_name} should have been defined"
    end
  end
  
  it "assigns the default value to an attribute that has not yet been set, if a default value has been specified" do
    @instance.test_attribute_with_default_value.must_equal "default value"
    @instance.test_attribute_with_type_and_default_value.must_equal 3
  end
  
  it "should allow overriding the default values" do
    instance = TestClass2.new( :test_attribute_with_default_value => "changed value" )
    instance.test_attribute_with_default_value.must_equal "changed value"
  end
  
  it "assumes an attribute's data type is string if the type has not been specified" do
    @instance.test_attribute.must_be_kind_of String
  end

  it "assigns the expected not-nil value to an attribute if a default value hasn't been specified" do
    @instance.test_attribute.must_equal ""
  end
  
  it "does not allow access to undefined attributes" do
    @instance.wont_respond_to "unknown_attribute"
    @instance.wont_respond_to "unknown_attribute="
    
    proc { @instance["unknown_attribute"] }.must_raise(NoMethodError)
    proc { @instance["unknown_attribute="] }.must_raise(NoMethodError)
  end
  
  it "shows the expected output on inspect" do
    @instance.inspect.must_equal "<#TestClass2 test_attribute=\"\" test_attribute_with_default_value=\"default value\" test_attribute_with_type_and_default_value=3>"
  end


  it "should not allow merging" do
    proc { @instance.merge(:new_symbol_key => "new_symbol_key") }.must_raise NoMethodError
  end
  
end


describe "An instance of TablelessModel" do
  before do
    class TestClass3 < ActiveRecord::TablelessModel
      attribute :typed_test_attribute,  :type => :integer
    end
  end

  describe "instance" do
    before do
      @instance = TestClass3.new
    end
    
    it "has rw the accessor __owner_object" do
      @instance.must_respond_to "__owner_object"
      @instance.must_respond_to "__owner_object="
    end

    it "has rw the accessor __serialized_attribute" do
      @instance.must_respond_to "__serialized_attribute"
      @instance.must_respond_to "__serialized_attribute="
    end
  end
  
  it "tries to enforce type casting if a type has been specified for an attribute" do

    test_values = [ "test", 1234, true, "1234.12", "2011-01-02 15:23" ]
    
    [ :string, :integer, :float, :decimal, :time, :date, :datetime, :boolean ].each do |type|

      # temporarily changing type
      TestClass3.attributes["typed_test_attribute"][:type] = type

      instance = TestClass3.new
      
      type_name = case type
      when :datetime then :date_time
      when :decimal then :big_decimal
      else type
      end
        
        
      # excluding some test values that would always fail depending on the type
      exclude_test_values = case type
      when :decimal then [ "test", true ]
      when :time then [ "test", 1234, true ]
      when :date then [ "test", 1234, true, "1234.12" ]
      when :datetime then [ "test", 1234, true ]
      else []
      end
        
      (test_values - exclude_test_values).each do |value|
        instance.typed_test_attribute = value
        
        if type == :boolean
          [true, false].include?(instance.typed_test_attribute).must_equal true, "Expected #{instance.typed_test_attribute.inspect} to be boolean, not #{type.class}"
        else
          instance.typed_test_attribute.must_be_kind_of type_name.to_s.classify.constantize
        end
      end

    end
  end
end

describe "An ActiveRecord::Base model" do
  before do
    class ModelOptions < ActiveRecord::TablelessModel
      attribute :aaa, :default => 111
      attribute :bbb, :default => "bbb"
    end

    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    ActiveRecord::Base.connection.execute(" create table test_models (options varchar(50)) ")

    class TestModel < ActiveRecord::Base
      has_tableless :options => ModelOptions
    end
  end

  it "responds to default_value_for, has_tableless" do
    TestModel.must_respond_to(:has_tableless)
  end
  
  
  describe "instance" do
    before do
      @instance = TestModel.new
    end
    
    it "must respond to changed?" do
      @instance.must_respond_to "changed?"
      @instance.changed?.must_equal false
      @instance.changes.must_equal({})
    end
    
    it "sets the accessor __owner_object to self in the tableless model instance" do
      @instance.options.__owner_object.must_equal @instance
    end
    
    it "sets the accessor __serialized_attribute to the name of its column that stored the tableless model instance, serialized" do
      @instance.options.__serialized_attribute.must_equal :options
    end
    
    
    it "has a getter and a setter for :options" do
      %w(options options=).each{|m| @instance.must_respond_to m }
      @instance.options.must_be_kind_of ModelOptions
      @instance.options.wont_be_nil
      @instance.options.aaa.must_equal "111"
      @instance.options.bbb.must_equal "bbb"
      proc { @instance.options = "test" }.must_raise NoMethodError, "should not accept other values than a hash or ModelOptions instance"
    end

    describe "setter" do
      before do
        @return_value = @instance.send("options=", { :aaa => "CCC", :bbb => "DDD"  })
      end

      it "correctly sets the serialized column" do
        @return_value.must_be_kind_of ModelOptions
        %w(aaa bbb).each{|m| @return_value.must_respond_to m}
        @instance.options.aaa.must_equal "CCC"
        @instance.options.bbb.must_equal "DDD"
      end
      
      it "forces the owner object to a changed state with partial_updates on" do
        @instance.options.aaa = "changed aaa"
        @instance.options.bbb = "changed bbb"

        @instance.options.aaa.must_equal "changed aaa"
        @instance.changes.keys.include?("options").must_equal true

        @instance.changes[:options][0].must_equal nil
        @instance.changes[:options][1].must_equal({"aaa"=>"changed aaa", "bbb"=>"changed bbb"})
      end

      it "should save the serialized column correctly" do
        @instance.save!
      
        instance = TestModel.first
        
        instance.options.aaa.must_equal "CCC"
        instance.options.bbb.must_equal "DDD"
        
         # Ensuring the serialize macro is used
        instance.options.must_be_kind_of ModelOptions
      end
    end
  end
end

  
