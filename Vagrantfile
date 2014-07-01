Vagrant.configure("2") do |config|
	config.berkshelf.enabled = true
  	config.omnibus.chef_version = :latest
	config.vm.hostname = "usergrid"
	config.vm.box = "precise64"
	config.vm.box_url = "http://files.vagrantup.com/precise64.box"
	config.vm.network :private_network, ip: "10.33.33.7"
	[ 8080, 9000 ].each do |port|
      config.vm.network :forwarded_port, guest: port, host: port, auto_correct: true
    end
	config.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--memory", 2048]
    	vb.customize ["modifyvm", :id, "--cpus", 2]
    end
    config.vm.provision :chef_solo do |chef|
    	chef.run_list = [
				"recipe[apt::default]",
				"recipe[git::default]",
				"recipe[java::default]",
				"recipe[maven::default]",
				"recipe[cassandra::tarball]",
				"recipe[tomcat::default]",
				"recipe[usergrid::default]"
		]
        chef.json.merge!({
        	:java => {
        		:install_flavor => "oracle",
        		:jdk_version => 7,
	            :oracle => {
	              "accept_oracle_download_terms" => true
	            }
            },
            :cassandra => {
            	:version => '1.2.15',
            	:jvm => {
            		:xms => 32,
            		:xmx => 512
            	},
            	:seeds => '127.0.0.1',
            	:initial_token => 0,
            	:listen_address => '127.0.0.1',
            	:broadcast_address => '127.0.0.1',
            	:rpc_address => '127.0.0.1'
            }
        })
      end
end
