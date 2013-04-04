require File.dirname(__FILE__) + '/base'

require 'fileutils'

describe Some do
	before do
		@work_path = "/tmp/spec_#{Process.pid}/"
		FileUtils.mkdir_p(@work_path)
		File.open("#{@work_path}/config.yml", "w") do |f|
			f.write YAML.dump({})
		end

		@some = Some.new
		@some.stubs(:some_dir).returns(@work_path)
	end

	after do
		FileUtils.rm_rf(@work_path)
	end

	it "defaults to user root if none is specified in the config" do
		@some.config['user'].should == 'root'
	end

	it "uses specified user if one is in the config" do
		File.open("#{@work_path}/config.yml", "w") do |f|
			f.write YAML.dump('user' => 'joe')
		end
		@some.config['user'].should == 'joe'
	end
end
