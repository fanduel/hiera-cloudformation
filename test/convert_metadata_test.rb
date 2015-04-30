require 'minitest/autorun'
require_relative '../lib/hiera/backend/cloudformation_backend'

class ConvertMetadataTest < MiniTest::Unit::TestCase

  class CloudformationBackendNoInit < Hiera::Backend::Cloudformation_backend
    def initialize
      # nope
    end
  end

  def setup
    @cfb = CloudformationBackendNoInit.new
  end

  def test_boolean
    assert_equal true, @cfb.convert_metadata('true')
    assert_equal false, @cfb.convert_metadata('false')
  end

  def test_nil
    assert_equal nil, @cfb.convert_metadata('null')
  end

  def test_integer
    assert_equal 1, @cfb.convert_metadata('1')
    assert_equal -1, @cfb.convert_metadata('-1')
  end

  def test_float
    assert_in_delta 1.0, @cfb.convert_metadata('1.0'), 0.001
    assert_in_delta -1.0, @cfb.convert_metadata('-1.0'), 0.001
  end

  def test_string
    assert_equal 'monkey', @cfb.convert_metadata('monkey')
    assert_equal '1.0.1', @cfb.convert_metadata('1.0.1')
    assert_equal 'True', @cfb.convert_metadata('True')
  end

  def test_array
    expected = [1, 2, 3, [4, 5, 6]]
    assert_equal expected, @cfb.convert_metadata(['1', '2', '3', ['4', '5', '6']])
  end

  def test_hash
    expected = { 'monkey' => { 'fez' => [1, 2, 3] } }
    assert_equal expected, @cfb.convert_metadata({ 'monkey' => { 'fez' => ['1', '2', '3'] } })
  end

end
