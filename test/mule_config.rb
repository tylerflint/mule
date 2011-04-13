
working_directory '/Users/tylerflint/Sites/gems/mule/test'

add_job do |j|
  j.file = 'job.rb'
  j.workers = 1
end
