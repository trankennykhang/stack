Vagrant.configure("2") do |config|
  # Use a standard Ubuntu box from the internet or your local template
  config.vm.box = "generic/ubuntu2404"
  
  # Use Libvirt (KVM) as the provider
  config.vm.provider :libvirt do |lv|
    lv.memory = 3072
    lv.cpus = 2
  end

  # Define the Master Node
  config.vm.define "shard-master" do |master|
    master.vm.hostname = "shard-master"
    master.vm.network "private_network", ip: "192.168.1.200"
  end

  # Define the Slave Node
  config.vm.define "shard-slave1" do |slave|
    slave.vm.hostname = "shard-slave1"
    slave.vm.network "private_network", ip: "192.168.1.201"
    
    # Example of Ansible Provisioning: 
    # Once the VM is up, Vagrant runs this automatically
    slave.vm.provision "ansible" do |ansible|
      ansible.playbook = "setup-mysql.yml"
    end
  end

  # Define the Slave Node
  config.vm.define "shard-slave2" do |slave|
    slave.vm.hostname = "shard-slave2"
    slave.vm.network "private_network", ip: "192.168.1.202"
    
    # Example of Ansible Provisioning: 
    # Once the VM is up, Vagrant runs this automatically
    slave.vm.provision "ansible" do |ansible|
      ansible.playbook = "setup-mysql.yml"
    end
  end
end
