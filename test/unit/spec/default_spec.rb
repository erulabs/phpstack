# Encoding: utf-8

require_relative 'spec_helper'

# the runlist came from test-kitchen's default suite
describe 'phpstack all in one demo' do
  recipes_for_demo = [
    'mysql_base',
    'postgresql_base',
    'mongodb_standalone',
    'memcache',
    'varnish',
    'rabbitmq',
    'redis_single',
    'application_php'
    ].map{|r| "phpstack::#{r}"}
  before { stub_resources }
  supported_platforms.each do |platform, versions|
    versions.each do |version|
      context "on #{platform.capitalize} #{version}" do
        let(:chef_run) do
          ChefSpec::Runner.new(platform: platform, version: version) do |node|
            node_resources(node) # stub this node
            stub_nodes(platform, version) # stub other nodes for chef-zero
            node.set['phpstack']['demo']['enabled'] = true
          end.converge(*recipes_for_demo) # *splat operator for array to vararg
        end

        property = load_platform_properties(platform: platform, platform_version: version)

        it 'renders /etc/phpstack.ini' do
          expect(chef_run).to create_template('/etc/phpstack.ini')
          [ '[MySQL-foo]',
            'master-host = 10.20.30.40',
            'slave-hosts = 10.20.20.20, 10.20.20.30',
            'port = 3306',
            'db_name = foo',
            'username = fooUser',
            'password = bar' ].each do |l|
            expect(chef_run).to render_file('/etc/phpstack.ini').with_content(/#{l}/i)
          end
        end
      end
    end
  end
end
