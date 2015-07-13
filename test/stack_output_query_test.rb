require 'minitest/autorun'
require 'minitest/mock'

require_relative '../lib/hiera/backend/cloudformation_backend'

class Hiera
  def self.debug(msg)
  end 
end

class ConvertMetadataTest < MiniTest::Unit::TestCase

  class MockCloudformationBackend < Hiera::Backend::Cloudformation_backend
    def initialize
      mock = MiniTest::Mock.new
      mock.expect(:get, nil, [ Hash ])
      mock.expect(:[], mock, [String])
      mock.expect(:stacks, mock)
      mock.expect(:outputs, [])
      mock_stack = [
        {"description"=>"The DNSName of ec2 instance", "key"=>"EC2InstancePublicDNS", "value"=>"ec2-54-72-167-37.eu-west-1.compute.amazonaws.com"}, 
        {"description"=>"The exposed endpoint for the RDS instance", "key"=>"MGMTDBEndpoint", "value"=>"mgt-rdsinstance.cjjwdugahibc.eu-west-1.rds.amazonaws.com:5432"}
      ]
      mock.expect(:put, mock_stack, [Hash, Object])
      @output_cache = mock
      
      @cf = mock

    end
  end

  def setup
    @cfb = MockCloudformationBackend.new
  end

  def test_resource_found
     assert @cfb.stack_output_query('MyStack', 'EC2InstancePublicDNS') == 'ec2-54-72-167-37.eu-west-1.compute.amazonaws.com'
  end

end
