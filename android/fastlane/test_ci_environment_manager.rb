#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/spec'
require 'json'
require 'fileutils'
require 'tmpdir'

# Mock Fastlane UI for testing
class MockUI
  def self.header(message); puts "HEADER: #{message}"; end
  def self.message(message); puts "MESSAGE: #{message}"; end
  def self.success(message); puts "SUCCESS: #{message}"; end
  def self.error(message); puts "ERROR: #{message}"; end
  def self.important(message); puts "IMPORTANT: #{message}"; end
  def self.user_error!(message); raise StandardError, message; end
end

# Replace UI with mock for testing
Object.const_set(:UI, MockUI)

require_relative 'ci_environment_manager'

describe CIEnvironmentManager do
  before do
    @original_env = ENV.to_h
    @temp_dir = Dir.mktmpdir
    @original_pwd = Dir.pwd
    Dir.chdir(@temp_dir)
    
    # Setup test environment
    ENV['CI'] = 'true'
    ENV['GITHUB_ACTIONS'] = 'true'
    ENV['GITHUB_RUN_NUMBER'] = '123'
    ENV['GITHUB_SHA'] = 'abc123def456'
    ENV['GITHUB_REF_NAME'] = 'main'
    ENV['GITHUB_WORKSPACE'] = @temp_dir
    ENV['GITHUB_REPOSITORY'] = 'test/repo'
    ENV['GITHUB_RUN_ID'] = '456789'
    
    # Create mock config structure
    FileUtils.mkdir_p('config/environments')
    config = {
      'environment' => { 'name' => 'development' },
      'app' => { 'name' => 'Test App' },
      'network' => { 'api_base_url' => 'https://api.test.com' },
      'signing' => { 'store_password_env' => 'STORE_PASSWORD' }
    }
    File.write('config/environments/development.yaml', config.to_yaml)
    
    # Mock ConfigLoader
    config_loader = Class.new do
      def self.load_environment_config(env)
        YAML.load_file("config/environments/#{env}.yaml")
      end
      
      def self.setup_flutter_environment(config)
        ENV['API_BASE_URL'] = config['network']['api_base_url']
      end
    end
    Object.const_set(:ConfigLoader, config_loader)
  end
  
  after do
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@temp_dir)
    ENV.clear
    ENV.update(@original_env)
  end
  
  describe '.setup_ci_environment' do
    it 'sets up CI environment successfully' do
      ENV['STORE_PASSWORD'] = 'test_password'
      
      # Should not raise an error
      CIEnvironmentManager.setup_ci_environment('development')
      
      # Check that environment variables are set
      assert_equal 'development', ENV['ENVIRONMENT']
      assert_equal 'https://api.test.com', ENV['API_BASE_URL']
      assert_equal 'true', ENV['FLUTTER_CI']
    end
    
    it 'validates CI requirements' do
      manager = CIEnvironmentManager.new('development')
      
      # Should validate without errors in test environment
      manager.validate_ci_requirements
    end
    
    it 'creates build metadata' do
      manager = CIEnvironmentManager.new('development')
      manager.setup_build_metadata
      
      metadata_file = File.join('build', 'ci', 'build-metadata.json')
      assert File.exist?(metadata_file)
      
      metadata = JSON.parse(File.read(metadata_file))
      assert_equal true, metadata['ci']
      assert_equal true, metadata['github_actions']
      assert_equal 'development', metadata['environment']
      assert_equal '123', metadata['build_number']
    end
  end
  
  describe '.validate_secrets' do
    it 'validates development secrets' do
      ENV['DEV_STORE_PASSWORD'] = 'dev_password'
      ENV['DEV_KEY_PASSWORD'] = 'dev_key_password'
      
      # Should not raise an error
      CIEnvironmentManager.validate_secrets('development')
    end
    
    it 'fails when secrets are missing' do
      # Clear secrets
      ENV.delete('DEV_STORE_PASSWORD')
      ENV.delete('DEV_KEY_PASSWORD')
      
      assert_raises(StandardError) do
        CIEnvironmentManager.validate_secrets('development')
      end
    end
    
    it 'validates production secrets' do
      ENV['PROD_STORE_PASSWORD'] = 'prod_password'
      ENV['PROD_KEY_PASSWORD'] = 'prod_key_password'
      
      # Should not raise an error
      CIEnvironmentManager.validate_secrets('production')
    end
  end
  
  describe '.generate_ci_report' do
    it 'generates comprehensive CI report' do
      report = CIEnvironmentManager.generate_ci_report('development')
      
      assert_equal 'development', report[:environment]
      assert_equal 'github_actions', report[:ci_platform]
      assert report[:build_info]
      assert report[:timestamp]
      
      # Check that report file is created
      report_files = Dir.glob('build/reports/ci-report-*.json')
      assert report_files.any?
    end
  end
  
  describe '.cleanup_ci_environment' do
    it 'cleans up sensitive files and environment variables' do
      # Create some sensitive files
      File.write('google-play-service-account.json', '{"test": "data"}')
      File.write('credentials.yaml', 'password: secret')
      
      # Set sensitive environment variables
      ENV['STORE_PASSWORD'] = 'secret'
      ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'] = 'secret_json'
      
      CIEnvironmentManager.cleanup_ci_environment
      
      # Check files are removed
      refute File.exist?('google-play-service-account.json')
      refute File.exist?('credentials.yaml')
      
      # Check environment variables are cleared
      assert_nil ENV['STORE_PASSWORD']
      assert_nil ENV['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON']
    end
  end
  
  describe 'CI platform detection' do
    it 'detects GitHub Actions' do
      platform = CIEnvironmentManager.send(:detect_ci_platform)
      assert_equal 'github_actions', platform
    end
    
    it 'detects GitLab CI' do
      ENV.delete('GITHUB_ACTIONS')
      ENV['GITLAB_CI'] = 'true'
      
      platform = CIEnvironmentManager.send(:detect_ci_platform)
      assert_equal 'gitlab_ci', platform
    end
    
    it 'detects unknown platform' do
      ENV.delete('GITHUB_ACTIONS')
      ENV.delete('GITLAB_CI')
      
      platform = CIEnvironmentManager.send(:detect_ci_platform)
      assert_equal 'unknown', platform
    end
  end
  
  describe 'build info collection' do
    it 'collects build information' do
      build_info = CIEnvironmentManager.send(:collect_build_info)
      
      assert_equal '123', build_info[:build_number]
      assert_equal 'abc123def456', build_info[:commit_sha]
      assert_equal 'main', build_info[:branch]
      assert build_info[:flutter_version]
      assert build_info[:fastlane_version]
    end
  end
end

# Run the tests
if __FILE__ == $0
  puts "Running CI Environment Manager tests..."
  Minitest.run([])
end