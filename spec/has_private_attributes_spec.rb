# frozen_string_literal: true

RSpec.describe HasPrivateAttributes do
  it 'has a version number' do
    expect(HasPrivateAttributes::VERSION).not_to be nil
  end

  let(:test_class) do
    Class.new do
      include HasPrivateAttributes

      private_attribute :static_servers, %w[1.1.1.1 8.8.8.8]

      private_attribute :lazy_servers do
        %w[2.2.2.2 3.3.3.3]
      end

      private_attribute :servers_by_region do |region|
        case region
        when 'us'
          %w[1.1.1.1 8.8.8.8]
        when 'eu'
          %w[2.2.2.2]
        end
      end

      def get_static_servers
        static_servers
      end

      def get_lazy_servers
        lazy_servers
      end

      def get_servers_by_region(region)
        servers_by_region(region)
      end

      def self.get_static_servers
        static_servers
      end
    end
  end

  let(:instance) { test_class.new }

  describe 'static attributes' do
    it 'returns the correct static value' do
      expect(instance.get_static_servers).to eq(%w[1.1.1.1 8.8.8.8])
    end

    it 'freezes the returned value' do
      expect(instance.get_static_servers).to be_frozen
    end

    it 'raises an error when trying to modify the returned value' do
      expect { instance.get_static_servers << '3.3.3.3' }.to raise_error(FrozenError)
    end
  end

  describe 'lazy attributes' do
    it 'returns the correct lazy-evaluated value' do
      expect(instance.get_lazy_servers).to eq(%w[2.2.2.2 3.3.3.3])
    end

    it 'freezes the returned value' do
      expect(instance.get_lazy_servers).to be_frozen
    end

    it 'caches the lazy-evaluated value' do
      expect(instance.get_lazy_servers.object_id).to eq(instance.get_lazy_servers.object_id)
    end
  end

  describe 'attributes with arguments' do
    it 'returns the correct value for different arguments' do
      expect(instance.get_servers_by_region('us')).to eq(%w[1.1.1.1 8.8.8.8])
      expect(instance.get_servers_by_region('eu')).to eq(%w[2.2.2.2])
    end

    it 'freezes the returned values' do
      expect(instance.get_servers_by_region('us')).to be_frozen
      expect(instance.get_servers_by_region('eu')).to be_frozen
    end

    it 'caches results for the same arguments' do
      first_call = instance.get_servers_by_region('us')
      second_call = instance.get_servers_by_region('us')
      expect(first_call).to eq(second_call)
    end

    it 'returns different objects for different arguments' do
      us_servers = instance.get_servers_by_region('us')
      eu_servers = instance.get_servers_by_region('eu')
      expect(us_servers.object_id).not_to eq(eu_servers.object_id)
    end
  end

  describe 'privacy' do
    it 'makes instance methods private' do
      expect { instance.static_servers }.to raise_error(NoMethodError)
      expect { instance.lazy_servers }.to raise_error(NoMethodError)
      expect { instance.servers_by_region('us') }.to raise_error(NoMethodError)
    end

    it 'makes class methods private' do
      expect { test_class.static_servers }.to raise_error(NoMethodError)
    end
  end

  describe 'class methods' do
    it 'allows private class methods to be called within the class' do
      expect(test_class.get_static_servers).to eq(%w[1.1.1.1 8.8.8.8])
    end

    it 'freezes the returned value for class methods' do
      expect(test_class.get_static_servers).to be_frozen
    end
  end

  describe 'inheritance' do
    let(:child_class) do
      Class.new(test_class) do
        private_attribute :child_attribute, 'child value'

        def get_child_attribute
          child_attribute
        end

        def get_parent_static_servers
          static_servers
        end
      end
    end

    let(:child_instance) { child_class.new }

    it 'inherits private attributes from the parent class' do
      expect(child_instance.get_parent_static_servers).to eq(%w[1.1.1.1 8.8.8.8])
    end

    it 'allows child classes to define their own private attributes' do
      expect(child_instance.get_child_attribute).to eq('child value')
    end
  end

  describe 'thread safety' do
    let(:thread_safe_class) do
      Class.new do
        include HasPrivateAttributes

        private_attribute :static_value, 0

        private_attribute :lazy_value do
          sleep 0.1 # Simulate some work
          42
        end

        def get_static_value
          static_value
        end

        def get_lazy_value
          lazy_value
        end

        def self.get_static_value
          static_value
        end
      end
    end

    let(:instance) { thread_safe_class.new }

    it 'handles concurrent access to static attributes' do
      threads = Array.new(10) do
        Thread.new { instance.get_static_value }
      end
      results = threads.map(&:value)
      expect(results.uniq.size).to eq(1)
    end

    it 'handles concurrent access to lazy attributes' do
      threads = Array.new(10) do
        Thread.new { instance.get_lazy_value }
      end
      results = threads.map(&:value)
      expect(results.uniq.size).to eq(1)
      expect(results.first).to eq(42)
    end

    it 'ensures thread safety for class-level attributes' do
      threads = Array.new(10) do
        Thread.new { thread_safe_class.get_static_value }
      end
      results = threads.map(&:value)
      expect(results.uniq.size).to eq(1)
    end
  end
end
