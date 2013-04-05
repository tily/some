require 'net/ssh'
require 'NIFTY'
require 'yaml'
require 'socket'

class Some
	def launch
		ami = config['ami']
		raise "No AMI selected" unless ami

		create_keypair unless File.exists? keypair_file

		create_security_group
		open_firewall(22)

		result = api.run_instances(
			:image_id => ami,
			:instance_type => config['instance_size'] || 'mini',
			:key_name => 'something',
			:security_group => 'something',
			:availability_zone => config['availability_zone'],
                        :disable_api_termination => false
		)
		result.instancesSet.item[0].instanceId
	end

	def list
		@list ||= fetch_list
	end

	def volumes
		result = api.describe_volumes
		return [] unless result.volumeSet

		result.volumeSet.item.map do |row|
			{
				:volume_id => row["volumeId"],
				:size => row["size"],
				:status => row["status"],
				:device => (row["attachmentSet"]["item"].first["device"] rescue ""),
				:instance_id => (row["attachmentSet"]["item"].first["instanceId"] rescue ""),
			}
		end
	end

	def available_volumes
		volumes.select { |vol| vol[:status] == 'available' }
	end

	def attached_volumes
		volumes.select { |vol| vol[:status] == 'in-use' }
	end

	def nondestroyed_volumes
		volumes.select { |vol| vol[:status] != 'deleting' }
	end

	def attach(volume, instance, device)
		result = api.attach_volume(
			:volume_id => volume,
			:instance_id => instance,
			:device => device
		)
		"done"
	end

	def detach(volume)
		result = api.detach_volume(:volume_id => volume, :force => "true")
		"done"
	end

	def create_volume(size)
		result = api.create_volume(
			:availability_zone => config['availability_zone'],
			:size => size.to_s
		)
		result["volumeId"]
	end

	def destroy_volume(volume)
		api.delete_volume(:volume_id => volume)
		"done"
	end

	def fetch_list
		result = api.describe_instances
		return [] unless result.reservationSet

		instances = []
		result.reservationSet.item.each do |r|
			r.instancesSet.item.each do |item|
				instances << {
					:instance_id => item.instanceId,
					:status => item.instanceState.name,
					:hostname => item.dnsName
				}
			end
		end
		instances
	end

	def find(id_or_hostname)
		return unless id_or_hostname
		id_or_hostname = id_or_hostname.strip.downcase
		list.detect do |inst|
			inst[:hostname] == id_or_hostname or
			inst[:instance_id] == id_or_hostname
		end
	end

	def find_volume(volume_id)
		return unless volume_id
		volume_id = volume_id.strip.downcase
		volumes.detect do |volume|
			volume[:volume_id] == volume_id or
			volume[:volume_id].gsub(/^vol-/, '') == volume_id
		end
	end

	def running
		list_by_status('running')
	end

	def pending
		list_by_status('pending')
	end

	def list_by_status(status)
		list.select { |i| i[:status] == status }
	end

	def instance_info(instance_id)
		fetch_list.detect do |inst|
			inst[:instance_id] == instance_id
		end
	end

	def wait_for_hostname(instance_id)
		raise ArgumentError unless instance_id
		loop do
			if inst = instance_info(instance_id)
				if hostname = inst[:hostname]
					return hostname
				end
			end
			sleep 1
		end
	end

	def wait_to_stop(instance_id)
		raise ArgumentError unless instance_id
                api.stop_instances(:instance_id => [ instance_id ])
                puts "waiting for #{instance_id} to stop "
		loop do
                        print '.'
			if inst = instance_info(instance_id)
				if inst[:status] == 'stopped'
                                        break
				end
			end
			sleep 5
		end
	end

	def wait_for_ssh(hostname)
		raise ArgumentError unless hostname
		loop do
			begin
				Timeout::timeout(4) do
					TCPSocket.new(hostname, 22)
					return
				end
			rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
			end
		end
	end

	def bootstrap_chef(hostname)
		commands = [
                        "curl -L https://www.opscode.com/chef/install.sh | bash",
                        "mkdir -p /var/chef/cookbooks /etc/chef",
                        "echo json_attribs \\'/etc/chef/dna.json\\' > /etc/chef/solo.rb"
		]
		ssh(hostname, commands)
	end

	def setup_role(hostname, role)
		commands = [
                        "echo \'#{config['role'][role]}\' > /etc/chef/dna.json",
			"chef-solo -r #{config['cookbooks_url']}"
		]
		ssh(hostname, commands)
	end

	def ssh(hostname, cmds)
                Net::SSH.start(hostname, config['user'], :keys => [keypair_file], :passphrase => config['password']) do |ssh|
                        File.open("#{ENV['HOME']}/.some/ssh.log", 'w') do |f|
                                f.write(ssh.exec!(cmds.join(' && ')))
                        end
                end
		# TODO: abort "failed\nCheck ~/.some/ssh.log for the output"
	end

	def resources(hostname)
		@resources ||= {}
		@resources[hostname] ||= fetch_resources(hostname)
	end

	def fetch_resources(hostname)
		cmd = "ssh -i #{keypair_file} #{config['user']}@#{hostname} 'cat /root/resources' 2>&1"
		out = IO.popen(cmd, 'r') { |pipe| pipe.read }
		abort "failed to read resources, output:\n#{out}" unless $?.success?
		parse_resources(out, hostname)
	end

	def parse_resources(raw, hostname)
		raw.split("\n").map do |line|
			line.gsub(/localhost/, hostname)
		end
	end

	def terminate(instance_id)
                inst = instance_info(instance_id)
                if inst[:status] != 'stopped'
                        api.stop_instances(:instance_id => [ instance_id ])
                        puts "waiting for #{instance_id} to stop "
		        loop do
                                print '.'
		        	if inst = instance_info(instance_id)
		        		if inst[:status] == 'stopped'
                                                break
		        		end
		        	end
		        	sleep 5
		        end
                end
		api.terminate_instances(:instance_id => [ instance_id ])
	end

	def console_output(instance_id)
		api.get_console_output(:instance_id => instance_id)["output"]
	end

	def config
		@config ||= default_config.merge read_config
	end

	def default_config
		{
			'user' => 'root',
			'ami' => 'ami-ed46a784',
			'availability_zone' => 'east-12',
                        'password' => 'password'
		}
	end

	def some_dir
		"#{ENV['HOME']}/.some"
	end

	def read_config
		YAML.load File.read("#{some_dir}/config.yml")
	rescue Errno::ENOENT
		raise "Some is not configured, please fill in ~/.some/config.yml"
	end

	def keypair_file
		"#{some_dir}/keypair.pem"
	end

	def create_keypair
		keypair = api.create_key_pair(:key_name => "something", :password => config['password']).keyMaterial
		File.open(keypair_file, 'w') { |f| f.write Base64.decode64(keypair) }
		File.chmod 0600, keypair_file
	end

	def create_security_group
		api.create_security_group(:group_name => 'something', :group_description => 'Something')
	rescue NIFTY::ResponseError => e
                if e.message != "The groupName 'something' already exists."
                        raise e
                end
	end

	def open_firewall(port)
		api.authorize_security_group_ingress(
			:group_name => 'something',
                        :ip_permissions => {
			        :ip_protocol => 'tcp',
			        :from_port => port,
			        :to_port => port,
			        :cidr_ip => '0.0.0.0/0'
                        }
		)
	rescue NIFTY::ResponseError => e
                raise e
	end

	def api
                @api ||= NIFTY::Cloud::Base.new(
                  :access_key => config['access_key'], 
                  :secret_key => config['secret_key'], 
                  :server => server,
                  :path => '/api'
                )
	end
	
	def server
	        zone = config['availability_zone']
	        host = zone.slice(0, zone.length - 1)
	        "#{host}.cp.cloud.nifty.com"
  end
end
