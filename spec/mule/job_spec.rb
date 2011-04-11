require 'spec_helper'

describe Mule::Job do
  
  it "allows setting procs for before and after forking events" do
    job = Mule::Job.new
    
    job.before_fork do
      1
    end
    
    job.after_fork do
      2
    end
    
    job.events[:before_fork].call.should == 1
    job.events[:after_fork].call.should == 2
  end
  
end