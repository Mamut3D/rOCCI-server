module Backends
  module Opennebula
    module Constants
      module Compute
        # State map
        STATE_MAP = {
          'RUNNING' => 'active',
          'PROLOG' => 'waiting',
          'BOOT' => 'waiting',
          'MIGRATE' => 'waiting',
          'EPILOG' => 'waiting'
        }.freeze

        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(vm) { vm['ID'] },
          'occi.core.title' => ->(vm) { vm['NAME'] },
          'occi.core.summary' => ->(vm) { vm['USER_TEMPLATE/DESCRIPTION'] }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.compute.state' => lambda do |vm|
            return 'waiting' if vm.lcm_state_str.include?('HOTPLUG')
            return 'error' if vm.lcm_state_str.include?('FAILURE')
            STATE_MAP[vm.lcm_state_str] || 'inactive'
          end,
          'occi.compute.userdata' => lambda do |vm|
            return unless vm['TEMPLATE/CONTEXT/USERDATA_ENCODING'] == 'base64'
            vm['TEMPLATE/CONTEXT/USER_DATA']
          end,
          'occi.credentials.ssh.publickey' => lambda do |vm|
            vm['TEMPLATE/CONTEXT/SSH_KEY'] || vm['TEMPLATE/CONTEXT/SSH_PUBLIC_KEY']
          end
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze

        # Attributes comparable between `resource_tpl` and `virtual_machine`
        COMPARABLE_ATTRIBUTES = {
          'occi.compute.cores' => ->(vm, val) { vm['TEMPLATE/VCPU'].to_i == val.to_i },
          'occi.compute.memory' => lambda do |vm, val|
            (vm['TEMPLATE/MEMORY'].to_f / 1024) == val.to_f
          end,
          'occi.compute.speed' => lambda do |vm, val|
            (vm['TEMPLATE/CPU'].to_f / vm['TEMPLATE/VCPU'].to_i) == val.to_f
          end,
          'occi.compute.ephemeral_storage.size' => lambda do |vm, val|
            (vm['TEMPLATE/DISK[1]/SIZE'].to_f / 1024) <= val.to_f
          end,
          'eu.egi.fedcloud.compute.pci.count' => lambda do |vm, val|
            vm.count_xpath('TEMPLATE/PCI') == val.to_i
          end,
          'eu.egi.fedcloud.compute.pci.vendor' => ->(vm, val) { vm['TEMPLATE/PCI[1]/VENDOR'] == val },
          'eu.egi.fedcloud.compute.pci.class' => ->(vm, val) { vm['TEMPLATE/PCI[1]/CLASS'] == val },
          'eu.egi.fedcloud.compute.pci.device' => ->(vm, val) { vm['TEMPLATE/PCI[1]/DEVICE'] == val }
        }.freeze

        # Mixins to add for contextualization attributes
        CONTEXT_MIXINS = [
          Occi::Infrastructure::Constants::USER_DATA_MIXIN,
          Occi::Infrastructure::Constants::SSH_KEY_MIXIN
        ].freeze
      end
    end
  end
end
