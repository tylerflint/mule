require 'spec_helper'

describe Mule::Grandmaster do

  context "startup" do
    
    it "creates a config instance" do
      
    end
    
    it "raises an exception when there aren't any jobs in the configurator instance" do
      
    end
    
    it "creates a master instance and passes the configurator instance" do
      
    end
  end
  
  context "signal handling" do
    
    it "accepts USR2 and creates a new master process, then sends a QUIT to the master process" do
      
    end
    
    it "accepts a QUIT, and passes a QUIT onto master, then waits until master exits before exiting" do
      
    end
    
    it "accepts an INT/TERM and sends the signal to the master, then exits immediately without waiting for cleanup" do
      
    end
  end
end