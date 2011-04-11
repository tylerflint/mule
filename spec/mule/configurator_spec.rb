require 'spec_helper'

describe Mule::Configurator do
  
  it "raises an exception when specified config file doesn't exist" do
    config = Mule::Configurator.new('/fake/file.rb')
    lambda { config.parse! }.should raise_error Mule::Error::MissingConfig
  end
  
  it "evaluates the contents of a config file in instance scope" do
    config_content = %{
      before_fork do
        1
      end
      
      after_fork do
        2
      end
    }
    config = Mule::Configurator.new('/fake/file.rb')
    config.stub!(:config_content).and_return(config_content)
    config.parse!
    config.events[:before_fork].call.should == 1
    config.events[:after_fork].call.should == 2
  end
  
  it "adds jobs" do
    config_content = %{
      add_job do |j|
        j.file = '/some/worker.rb'
        j.workers = 2
        j.before_fork do
          1
        end
      end
      
      add_job do |j|
        j.file = '/some/other/worker.rb'
        j.workers = 4
        j.before_fork do
          2
        end
      end
    }
    config = Mule::Configurator.new('/fake/file.rb')
    config.stub!(:config_content).and_return(config_content)
    config.parse!
    config.jobs.length.should == 2
    config.jobs[0].file.should == '/some/worker.rb'
    config.jobs[0].workers.should == 2
    config.jobs[0].events[:before_fork].call.should == 1
  end
  
end