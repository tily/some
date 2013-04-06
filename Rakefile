require 'jeweler'

Jeweler::Tasks.new do |s|
	s.name = "some"
	s.description = "sumo clone for NIFTY Cloud"
	s.summary = s.description
	s.author = "tily"
	s.email = "tidnlyam@gmail.com"
	s.homepage = "http://github.com/tily/some"
	s.rubyforge_project = "some"
	s.files = FileList["[A-Z]*", "{bin,lib,spec}/**/*"]
	s.executables = %w(some)
	s.add_dependency "nifty-cloud-sdk", "1.11.beta1"
	s.add_dependency "thor"
end

Jeweler::RubyforgeTasks.new

desc 'Run specs'
task :spec do
	sh 'bacon -s spec/*_spec.rb'
end

task :default => :spec

