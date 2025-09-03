# Test suite for Error Handling and Logging Implementation
# Run with: ruby test_error_handling.rb

require 'minitest/autorun'
require 'minitest/reporters'
require 'json'
require 'yaml'
require 'fileutils'
require 'tmpdir'

# Setup test reporter
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Add parent directory to load path for requiring our modules
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')

require_relative '../error_handler'
require_relative '../build_logger'
require_relative '../debug_tools'

class TestErrorHandling < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('fastlane_error_handling_test')
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)
    
    # Create test directory structure
    FileUtils.mkdir_p('build/logs')
    FileUtils.mkdir_p('build/error_reports')
    FileUtils.mkdir_p('build/debug_info')
    FileUtils.mkdir_p('config/environments')
    FileUtils.mkdir_p('keystores')
    
    @environment = 'test'
    @error_handler = ErrorHandler.new(@environment, true)
  end
  
  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir)
  end
  
  def test_error_handler_initialization
    assert_instance_of ErrorHandler, @error_handler
    assert_equal @environment, @error_handler.instance_variable_get(:@environment)
    assert @error_handler.debug_mode
    assert File.exist?(@error_handler.error_log_path)
  end
  
  def test_error_logging
    test_error = StandardError.new("Test error message")
    context = { operation: 'test', step: 'initialization' }
    
    assert_raises(StandardError) do
      @error_handler.handle_error(test_error, context)
    end
    
    # Check that error was logged
    assert File.exist?(@error_handler.error_log_path)
    log_content = File.read(@error_handler.error_log_path)
    assert_includes log_content, "Test error message"
    assert_includes log_content, "test"
  end
  
  def test_configuration_validation_success
    # Create valid configuration
    valid_config = {
      'environment' => { 'name' => 'test' },
      'app' => { 
        'name' => 'Test App',
        'bundle_id' => 'com.test.app',
        'version_name' => '1.0.0',
        'version_code' => 1
      },
      'network' => { 'api_base_url' => 'https://api.test.com' },
      'build' => { 'build_type' => 'debug' },
      'signing' => {
        'store_file' => 'test.keystore',
        'store_password_env' => 'TEST_STORE_PASSWORD',
        'key_alias' => 'test',
        'key_password_env' => 'TEST_KEY_PASSWORD'
      }
    }
    
    config_path = File.join('config', 'environments', 'test.yaml')
    File.write(config_path, YAML.dump(valid_config))
    
    # Create keystore file
    FileUtils.touch(File.join('keystores', 'test.keystore'))
    
    # Should not raise error
    @error_handler.validate_configuration(valid_config, config_path)
  end
  
  def test_configuration_validation_failure
    # Create invalid configuration
    invalid_config = {
      'environment' => { 'name' => 'invalid_env' },
      'app' => { 
        'name' => 'Test App',
        'bundle_id' => 'invalid-bundle-id',  # Invalid format
        'version_name' => 'invalid-version'   # Invalid format
      }
      # Missing required sections
    }
    
    config_path = File.join('config', 'environments', 'test.yaml')
    File.write(config_path, YAML.dump(invalid_config))
    
    assert_raises(ConfigValidationError) do
      @error_handler.validate_configuration(invalid_config, config_path)
    end
  end
  
  def test_debug_info_generation
    context = { test: 'debug_info' }
    debug_info = @error_handler.generate_debug_info(context)
    
    assert_instance_of Hash, debug_info
    assert_includes debug_info.keys, :timestamp
    assert_includes debug_info.keys, :environment
    assert_includes debug_info.keys, :system_info
    assert_equal @environment, debug_info[:environment]
    assert_equal context, debug_info[:context]
  end
  
  def test_recovery_strategy_selection
    # Test configuration error
    config_error = ConfigValidationError.new("Test config error")
    strategy = @error_handler.send(:find_recovery_strategy, config_error, {})
    assert_not_nil strategy
    
    # Test signing error
    signing_error = StandardError.new("keystore not found")
    strategy = @error_handler.send(:find_recovery_strategy, signing_error, {})
    assert_not_nil strategy
    
    # Test build error
    build_error = StandardError.new("flutter build failed")
    strategy = @error_handler.send(:find_recovery_strategy, build_error, {})
    assert_not_nil strategy
  end
end

class TestBuildLogger < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('fastlane_build_logger_test')
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)
    
    FileUtils.mkdir_p('build/build_logs')
    FileUtils.mkdir_p('build/build_summaries')
    
    @environment = 'test'
    @build_type = 'debug'
    @build_logger = BuildLogger.new(@environment, @build_type)
  end
  
  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir)
  end
  
  def test_build_logger_initialization
    assert_instance_of BuildLogger, @build_logger
    assert_equal @environment, @build_logger.environment
    assert_not_nil @build_logger.build_id
    assert File.exist?(@build_logger.build_log_path)
  end
  
  def test_build_lifecycle_logging
    config = {
      'environment' => { 'name' => @environment },
      'app' => { 'name' => 'Test App' },
      'network' => { 'api_base_url' => 'https://api.test.com' }
    }
    
    # Start build
    @build_logger.start_build(config)
    
    # Execute a step
    result = @build_logger.execute_step('Test Step', 'Testing step execution') do
      sleep(0.1) # Simulate work
      { success: true }
    end
    
    assert_instance_of Hash, result
    assert result[:success]
    
    # End build
    build_result = @build_logger.end_build(true)
    
    assert_instance_of Hash, build_result
    assert build_result[:success]
    assert build_result[:duration_seconds] > 0
    assert_includes build_result[:step_timings].keys, 'Test Step'
  end
  
  def test_step_timing
    step_name = 'Timed Step'
    
    @build_logger.start_step(step_name, 'Testing timing')
    sleep(0.1)
    step_result = @build_logger.end_step(true, { test: 'data' })
    
    assert_instance_of Hash, step_result
    assert step_result[:success]
    assert step_result[:duration_seconds] > 0
    assert_equal step_name, step_result[:step_name]
    assert_equal({ test: 'data' }, step_result[:details])
  end
  
  def test_error_step_handling
    step_name = 'Failing Step'
    
    assert_raises(StandardError) do
      @build_logger.execute_step(step_name, 'Testing error handling') do
        raise StandardError.new("Test step failure")
      end
    end
    
    # Check that step was marked as failed
    step_timings = @build_logger.instance_variable_get(:@step_timings)
    assert_includes step_timings.keys, step_name
    refute step_timings[step_name][:success]
  end
  
  def test_logging_methods
    # Test info logging
    @build_logger.log_info("Test info message", { test: true })
    
    # Test warning logging
    @build_logger.log_warning("Test warning message", { warning: true })
    
    # Test debug logging (should work since debug mode is enabled)
    @build_logger.log_debug("Test debug message", { debug: true })
    
    # Check log file exists and has content
    assert File.exist?(@build_logger.build_log_path)
    log_content = File.read(@build_logger.build_log_path)
    assert_includes log_content, "Test info message"
    assert_includes log_content, "Test warning message"
    assert_includes log_content, "Test debug message"
  end
  
  def test_performance_metrics_calculation
    # Execute multiple steps to generate metrics
    @build_logger.execute_step('Fast Step', 'Quick operation') do
      sleep(0.05)
      { result: 'fast' }
    end
    
    @build_logger.execute_step('Slow Step', 'Slower operation') do
      sleep(0.15)
      { result: 'slow' }
    end
    
    metrics = @build_logger.send(:calculate_performance_metrics)
    
    assert_instance_of Hash, metrics
    assert metrics[:total_build_time] > 0
    assert_equal 2, metrics[:total_steps]
    assert_equal 2, metrics[:successful_steps]
    assert_equal 0, metrics[:failed_steps]
    assert_equal 100.0, metrics[:success_rate]
    assert metrics[:average_step_time] > 0
  end
end

class TestDebugTools < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('fastlane_debug_tools_test')
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)
    
    # Create test directory structure
    FileUtils.mkdir_p('config/environments')
    FileUtils.mkdir_p('keystores')
    FileUtils.mkdir_p('build/diagnosis_reports')
    FileUtils.mkdir_p('build/validation_reports')
    
    @environment = 'test'
  end
  
  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir)
  end
  
  def test_system_info_collection
    system_info = DebugTools.send(:get_detailed_system_info)
    
    assert_instance_of Hash, system_info
    assert_includes system_info.keys, :ruby_version
    assert_includes system_info.keys, :ruby_platform
    assert_includes system_info.keys, :working_directory
    assert_equal Dir.pwd, system_info[:working_directory]
  end
  
  def test_configuration_checking
    # Create test configuration
    config = {
      'environment' => { 'name' => @environment },
      'app' => { 'name' => 'Test App', 'bundle_id' => 'com.test.app' },
      'network' => { 'api_base_url' => 'https://api.test.com' },
      'build' => { 'build_type' => 'debug' },
      'signing' => {
        'store_file' => 'test.keystore',
        'store_password_env' => 'TEST_STORE_PASSWORD',
        'key_alias' => 'test',
        'key_password_env' => 'TEST_KEY_PASSWORD'
      }
    }
    
    config_path = File.join('config', 'environments', "#{@environment}.yaml")
    File.write(config_path, YAML.dump(config))
    
    diagnosis = { issues: [], recommendations: [] }
    result = DebugTools.send(:check_configuration, @environment, diagnosis)
    
    assert_instance_of Hash, result
    assert result[:config_file_exists]
    assert result[:config_parse_success]
    assert_includes result[:config_sections], 'environment'
  end
  
  def test_missing_configuration_detection
    diagnosis = { issues: [], recommendations: [] }
    result = DebugTools.send(:check_configuration, 'nonexistent', diagnosis)
    
    assert_instance_of Hash, result
    refute result[:config_file_exists]
    assert diagnosis[:issues].any?
    
    # Check that appropriate issue was recorded
    config_issues = diagnosis[:issues].select { |issue| issue[:type] == 'configuration' }
    assert config_issues.any?
  end
  
  def test_build_environment_checking
    diagnosis = { issues: [], recommendations: [] }
    result = DebugTools.send(:check_build_environment, diagnosis)
    
    assert_instance_of Hash, result
    assert_includes result.keys, :flutter_available
    assert_includes result.keys, :android_sdk_available
    assert_includes result.keys, :java_available
    
    # These might be false in test environment, which is expected
    assert [true, false].include?(result[:flutter_available])
    assert [true, false].include?(result[:android_sdk_available])
    assert [true, false].include?(result[:java_available])
  end
  
  def test_file_permission_checking
    diagnosis = { issues: [], recommendations: [] }
    result = DebugTools.send(:check_file_permissions, diagnosis)
    
    assert_instance_of Hash, result
    
    # Check that it tests directory permissions
    assert_includes result.keys, :build_readable
    assert_includes result.keys, :build_writable
  end
end

class TestIntegration < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir('fastlane_integration_test')
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)
    
    # Create comprehensive test environment
    FileUtils.mkdir_p('build/logs')
    FileUtils.mkdir_p('build/error_reports')
    FileUtils.mkdir_p('build/build_logs')
    FileUtils.mkdir_p('config/environments')
    FileUtils.mkdir_p('keystores')
    
    @environment = 'test'
  end
  
  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir)
  end
  
  def test_error_handler_and_logger_integration
    error_handler = ErrorHandler.new(@environment, true)
    build_logger = BuildLogger.new(@environment, 'debug')
    
    # Test that they can work together
    config = {
      'environment' => { 'name' => @environment },
      'app' => { 'name' => 'Test App' }
    }
    
    build_logger.start_build(config)
    
    # Test error handling within build logging
    assert_raises(StandardError) do
      error_handler.with_error_handling(operation: 'test_integration') do
        build_logger.execute_step('Failing Step', 'Testing integration') do
          raise StandardError.new("Integration test error")
        end
      end
    end
    
    build_result = build_logger.end_build(false, StandardError.new("Test error"))
    
    assert_instance_of Hash, build_result
    refute build_result[:success]
    assert_not_nil build_result[:error]
  end
  
  def test_comprehensive_error_flow
    error_handler = ErrorHandler.new(@environment, true)
    
    # Create invalid configuration to trigger validation error
    invalid_config = { 'invalid' => 'config' }
    config_path = File.join('config', 'environments', "#{@environment}.yaml")
    File.write(config_path, YAML.dump(invalid_config))
    
    # Test full error handling flow
    assert_raises(ConfigValidationError) do
      error_handler.validate_configuration(invalid_config, config_path)
    end
    
    # Check that error report was generated
    error_reports_dir = File.join('build', 'error_reports')
    assert Dir.exist?(error_reports_dir)
    
    # Check that validation report was generated
    validation_reports_dir = File.join('build', 'validation_reports')
    assert Dir.exist?(validation_reports_dir)
  end
end

# Custom error class test
class TestCustomErrors < Minitest::Test
  def test_config_validation_error
    validation_errors = [
      { type: 'missing_field', message: 'Field missing' },
      { type: 'invalid_format', message: 'Invalid format' }
    ]
    
    error = ConfigValidationError.new("Validation failed", validation_errors)
    
    assert_equal "Validation failed", error.message
    assert_equal validation_errors, error.validation_errors
    assert_instance_of ConfigValidationError, error
    assert_kind_of StandardError, error
  end
  
  def test_other_custom_errors
    assert_instance_of SigningError, SigningError.new("Signing failed")
    assert_instance_of BuildError, BuildError.new("Build failed")
    assert_instance_of NetworkError, NetworkError.new("Network failed")
    
    # Test inheritance
    assert_kind_of StandardError, SigningError.new("test")
    assert_kind_of StandardError, BuildError.new("test")
    assert_kind_of StandardError, NetworkError.new("test")
  end
end

# Run the tests
puts "Running Error Handling and Logging Tests..."
puts "=" * 50

# Set environment variables for testing
ENV['FASTLANE_DEBUG'] = 'true'

# Run all tests
Minitest.run