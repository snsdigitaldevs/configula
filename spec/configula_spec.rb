require File.join(File.dirname( __FILE__ ), 'spec_helper')

describe Configula do
  class MyConfig < Configula
    def initialize
      set :string_config, "some_string_value"
      set :proc_config, lambda{ "this is a proc: #{string_config}" }
    end
  end
  
  before(:all) do
    MY_CONFIG = MyConfig.new
    MyConfig.lock
  end
  
  it "should return the config value when it is a string " do
    MY_CONFIG.string_config.should == "some_string_value"
  end
  
  it "should call the proec config when it is a proc " do
    MY_CONFIG.proc_config.should == "this is a proc: some_string_value"
  end
end