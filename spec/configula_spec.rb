require File.join(File.dirname( __FILE__ ), 'spec_helper')

describe Configula do
  class MyConfig < Configula
    def initialize
      set :string_config, "some_string_value"
      set :proc_config, lambda{ "this is a proc: #{string_config}" }
      #set :something_with_nil, nil
      #p "yo yo yo"
      #something(:with_nil => nil)
      
      another_config "another_config"
      self.config_equals = "config_equals"
      chaining.config = "chaining config"
    end
  end
  
  it "should allow setting of values with set" do
    MyConfig.new.string_config.should == "some_string_value"
  end
  
  it "should allow setting of values by calling the config as a method" do
    MyConfig.new.another_config.should == "another_config"
  end
  
  it "should allow setting of values by calling the config as a method=" do
    MyConfig.new.config_equals.should == "config_equals"
  end
  
  it "should multi step chaining config" do
    MyConfig.new.chaining.config.should == "chaining config"
  end
  
  it "should not wire up method missing configula 'wire ups' on nil when it is passed in as a return value with the hash setting method" do
    MyConfig.new.something(:with_nil => nil)
    Configula.should_not_receive(:wire_up)
    lambda { nil.some_missing_method }.should raise_error("undefined method `some_missing_method' for nil:NilClass")
  end
  
  it "should allow overriding of the values with inherting" do
    class InheritedConfig < MyConfig
      def initialize
        super
        set :string_config, "new string value"
        self.config_equals = "new config equals"
        chaining.config = "new config chaining"
      end
    end
    
    InheritedConfig.new.string_config.should == "new string value"
    InheritedConfig.new.config_equals.should == "new config equals"
    InheritedConfig.new.chaining.config.should == "new config chaining"
  end
  
  it "should return nil value for unknown config" do
    config = MyConfig.new
    MyConfig.lock
    config.string_config.should == "some_string_value"
    config.some_unknown_key.should == nil
    MyConfig.unlock
  end
  
  it "should not allow changes without locking" do
    MyConfig.lock
    
    class InheritedConfig < MyConfig
      def initialize
        super
        set :string_config, "new string value"
        self.config_equals = "new config equals"
        chaining.config = "new config chaining"
      end
    end
    
    lambda { InheritedConfig.new }.should raise_error
    
    MyConfig.unlock
  end
  
  describe "storing value" do
    before(:each) do
      MyConfig.unlock
      @config = MyConfig.new
      MyConfig.lock
    end
    
    after(:each) do
      MyConfig.unlock
    end
    
    it "should return the config value when it is a string " do
      @config.string_config.should == "some_string_value"
    end

    it "should call the proc config when it is a proc " do
      @config.proc_config.should == "this is a proc: some_string_value"
    end
    
  end
  
end