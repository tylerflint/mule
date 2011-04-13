
working_directory '/var/mule/test'

add_job do |j|
  j.file = 'job.rb'
  j.workers = 10
end
