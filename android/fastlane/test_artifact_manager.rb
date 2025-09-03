#!/usr/bin/env ruby

require_relative 'config_loader'
require_relative 'artifact_manager'
require 'fileutils'
require 'json'

class ArtifactManagerTest
  def self.run_tests
    puts "🧪 Running ArtifactManager tests..."
    
    # Setup test environment
    setup_test_environment
    
    # Test 1: Basic artifact organization
    test_basic_artifact_organization
    
    # Test 2: Filename generation
    test_filename_generation
    
    # Test 3: Metadata generation
    test_metadata_generation
    
    # Test 4: Checksum validation
    test_checksum_validation
    
    # Test 5: Build directory structure
    test_build_directory_structure
    
    # Cleanup
    cleanup_test_environment
    
    puts "✅ All ArtifactManager tests passed!"
  end
  
  private
  
  def self.setup_test_environment
    puts "🔧 Setting up test environment..."
    
    # Create test build directory
    @test_build_dir = File.join(Dir.pwd, '..', '..', 'build', 'test')
    FileUtils.mkdir_p(@test_build_dir)
    
    # Create mock Flutter build outputs
    flutter_apk_dir = File.join(@test_build_dir, 'app', 'outputs', 'flutter-apk')
    flutter_aab_dir = File.join(@test_build_dir, 'app', 'outputs', 'bundle', 'release')
    
    FileUtils.mkdir_p(flutter_apk_dir)
    FileUtils.mkdir_p(flutter_aab_dir)
    
    # Create mock APK and AAB files
    File.write(File.join(flutter_apk_dir, 'app-debug.apk'), 'mock apk content for debug')
    File.write(File.join(flutter_apk_dir, 'app-release.apk'), 'mock apk content for release')
    File.write(File.join(flutter_aab_dir, 'app-release.aab'), 'mock aab content for release')
    
    puts "✅ Test environment setup complete"
  end
  
  def self.test_basic_artifact_organization
    puts "🧪 Testing basic artifact organization..."
    
    config = {
      'environment' => { 'name' => 'test' },
      'app' => {
        'name' => 'Test App',
        'bundle_id' => 'com.test.app',
        'version_name' => '1.0.0',
        'version_code' => 1
      },
      'network' => {
        'api_base_url' => 'https://api.test.com',
        'websocket_url' => 'wss://ws.test.com'
      },
      'build' => {
        'flavor' => 'test',
        'obfuscate' => false,
        'shrink_resources' => false
      }
    }
    
    # Temporarily redirect Flutter build paths for testing
    original_pwd = Dir.pwd
    Dir.chdir(@test_build_dir)
    
    begin
      artifact_manager = ArtifactManager.new(config, 'debug')
      
      # Mock the Flutter build directory structure
      FileUtils.mkdir_p('app/outputs/flutter-apk')
      FileUtils.mkdir_p('app/outputs/bundle/release')
      File.write('app/outputs/flutter-apk/app-debug.apk', 'mock debug apk')
      File.write('app/outputs/flutter-apk/app-release.apk', 'mock release apk')
      File.write('app/outputs/bundle/release/app-release.aab', 'mock release aab')
      
      result = artifact_manager.organize_build_artifacts
      
      # Verify result structure
      raise "Missing build_directory" unless result[:build_directory]
      raise "Missing metadata" unless result[:metadata]
      raise "Missing apk_info" unless result[:apk_info]
      raise "Missing aab_info" unless result[:aab_info]
      
      puts "✅ Basic artifact organization test passed"
      
    ensure
      Dir.chdir(original_pwd)
    end
  end
  
  def self.test_filename_generation
    puts "🧪 Testing filename generation..."
    
    config = {
      'environment' => { 'name' => 'production' },
      'app' => {
        'name' => 'My Test App',
        'version_name' => '2.1.0',
        'version_code' => 42
      },
      'build' => { 'build_type' => 'release' }
    }
    
    artifact_manager = ArtifactManager.new(config, 'release')
    
    # Test APK filename generation
    apk_filename = artifact_manager.send(:generate_apk_filename, 'app-release.apk')
    expected_pattern = /^my-test-app-production-release-v2\.1\.0-42-\d{8}-\d{6}\.apk$/
    
    unless apk_filename.match?(expected_pattern)
      raise "APK filename doesn't match expected pattern: #{apk_filename}"
    end
    
    # Test AAB filename generation
    aab_filename = artifact_manager.send(:generate_aab_filename, 'app-release.aab')
    expected_aab_pattern = /^my-test-app-production-release-v2\.1\.0-42-\d{8}-\d{6}\.aab$/
    
    unless aab_filename.match?(expected_aab_pattern)
      raise "AAB filename doesn't match expected pattern: #{aab_filename}"
    end
    
    puts "✅ Filename generation test passed"
  end
  
  def self.test_metadata_generation
    puts "🧪 Testing metadata generation..."
    
    config = {
      'environment' => { 'name' => 'staging' },
      'app' => {
        'name' => 'Staging App',
        'bundle_id' => 'com.staging.app',
        'version_name' => '1.5.0',
        'version_code' => 15
      },
      'network' => {
        'api_base_url' => 'https://staging-api.test.com',
        'websocket_url' => 'wss://staging-ws.test.com'
      },
      'build' => {
        'flavor' => 'staging',
        'obfuscate' => true,
        'shrink_resources' => true
      }
    }
    
    artifact_manager = ArtifactManager.new(config, 'release')
    
    apk_info = [
      {
        filename: 'test-app.apk',
        size: 1024,
        checksum: 'abc123',
        build_type: 'release'
      }
    ]
    
    aab_info = [
      {
        filename: 'test-app.aab',
        size: 2048,
        checksum: 'def456',
        build_type: 'release'
      }
    ]
    
    metadata = artifact_manager.send(:generate_build_metadata, apk_info, aab_info)
    
    # Verify metadata structure
    raise "Missing build_info" unless metadata[:build_info]
    raise "Missing configuration" unless metadata[:configuration]
    raise "Missing artifacts" unless metadata[:artifacts]
    raise "Missing git_info" unless metadata[:git_info]
    raise "Missing system_info" unless metadata[:system_info]
    
    # Verify build_info content
    build_info = metadata[:build_info]
    raise "Wrong environment" unless build_info[:environment] == 'staging'
    raise "Wrong app_name" unless build_info[:app_name] == 'Staging App'
    raise "Wrong version_name" unless build_info[:version_name] == '1.5.0'
    
    # Verify artifacts content
    artifacts = metadata[:artifacts]
    raise "Wrong APK count" unless artifacts[:apk_files].length == 1
    raise "Wrong AAB count" unless artifacts[:aab_files].length == 1
    
    puts "✅ Metadata generation test passed"
  end
  
  def self.test_checksum_validation
    puts "🧪 Testing checksum validation..."
    
    # Create a temporary file for checksum testing
    test_file = File.join(@test_build_dir, 'test_checksum.txt')
    File.write(test_file, 'test content for checksum')
    
    config = {
      'environment' => { 'name' => 'test' },
      'app' => { 'name' => 'Test', 'version_name' => '1.0.0', 'version_code' => 1 },
      'network' => { 'api_base_url' => 'http://test.com' },
      'build' => {}
    }
    
    artifact_manager = ArtifactManager.new(config, 'debug')
    
    # Calculate checksum
    checksum1 = artifact_manager.send(:calculate_checksum, test_file)
    checksum2 = artifact_manager.send(:calculate_checksum, test_file)
    
    # Checksums should be identical for the same file
    raise "Checksums don't match" unless checksum1 == checksum2
    
    # Checksum should be a valid SHA256 hex string
    raise "Invalid checksum format" unless checksum1.match?(/^[a-f0-9]{64}$/)
    
    # Modify file and verify checksum changes
    File.write(test_file, 'modified content')
    checksum3 = artifact_manager.send(:calculate_checksum, test_file)
    
    raise "Checksum didn't change after file modification" if checksum1 == checksum3
    
    puts "✅ Checksum validation test passed"
  end
  
  def self.test_build_directory_structure
    puts "🧪 Testing build directory structure..."
    
    config = {
      'environment' => { 'name' => 'test' },
      'app' => {
        'name' => 'Structure Test',
        'version_name' => '1.0.0',
        'version_code' => 1
      },
      'network' => { 'api_base_url' => 'http://test.com' },
      'build' => {}
    }
    
    artifact_manager = ArtifactManager.new(config, 'debug')
    
    build_dir = artifact_manager.send(:create_build_directory)
    
    # Verify directory structure
    expected_subdirs = %w[apk aab metadata logs]
    expected_subdirs.each do |subdir|
      subdir_path = File.join(build_dir, subdir)
      raise "Missing subdirectory: #{subdir}" unless Dir.exist?(subdir_path)
    end
    
    # Verify latest symlink
    env_dir = File.dirname(build_dir)
    latest_link = File.join(env_dir, 'latest')
    raise "Latest symlink not created" unless File.symlink?(latest_link)
    raise "Latest symlink points to wrong directory" unless File.readlink(latest_link) == File.basename(build_dir)
    
    puts "✅ Build directory structure test passed"
  end
  
  def self.cleanup_test_environment
    puts "🧹 Cleaning up test environment..."
    
    if @test_build_dir && Dir.exist?(@test_build_dir)
      FileUtils.rm_rf(@test_build_dir)
    end
    
    # Clean up any test artifacts in the main build directory
    test_android_dir = File.join(Dir.pwd, '..', '..', 'build', 'android', 'test')
    if Dir.exist?(test_android_dir)
      FileUtils.rm_rf(test_android_dir)
    end
    
    puts "✅ Test environment cleaned up"
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  ArtifactManagerTest.run_tests
end