#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/spec'
require 'json'
require 'fileutils'
require 'tmpdir'
require 'digest'

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

require_relative 'ci_artifact_manager'

describe CIArtifactManager do
  before do
    @original_env = ENV.to_h
    @temp_dir = Dir.mktmpdir
    @original_pwd = Dir.pwd
    Dir.chdir(@temp_dir)
    
    # Setup test environment
    ENV['CI'] = 'true'
    ENV['GITHUB_ACTIONS'] = 'true'
    ENV['BUILD_NUMBER'] = '123'
    ENV['GITHUB_RUN_NUMBER'] = '123'
    ENV['COMMIT_SHA'] = 'abc123def456'
    ENV['GITHUB_SHA'] = 'abc123def456'
    ENV['GITHUB_WORKSPACE'] = @temp_dir
    
    # Create mock build structure
    setup_mock_build_artifacts
  end
  
  after do
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@temp_dir)
    ENV.clear
    ENV.update(@original_env)
  end
  
  def setup_mock_build_artifacts
    # Create Flutter build output structure
    build_dir = File.join('build', 'app', 'outputs', 'flutter-apk')
    FileUtils.mkdir_p(build_dir)
    
    # Create mock APK file
    apk_content = 'mock apk content for testing'
    apk_path = File.join(build_dir, 'app-release.apk')
    File.write(apk_path, apk_content)
    
    # Create mock AAB file
    aab_dir = File.join('build', 'app', 'outputs', 'bundle', 'release')
    FileUtils.mkdir_p(aab_dir)
    
    aab_content = 'mock aab content for testing'
    aab_path = File.join(aab_dir, 'app-release.aab')
    File.write(aab_path, aab_content)
  end
  
  describe '.organize_ci_artifacts' do
    it 'organizes artifacts for CI environment' do
      artifact_info = CIArtifactManager.organize_ci_artifacts('development', 'debug')
      
      assert artifact_info[:build_directory]
      assert artifact_info[:artifacts]
      assert artifact_info[:metadata]
      
      # Check that CI build directory is created
      assert Dir.exist?(artifact_info[:build_directory])
      
      # Check that artifacts are organized by type
      artifacts = artifact_info[:artifacts]
      assert artifacts[:apk]
      assert artifacts[:aab]
      
      # Check that checksums are generated
      artifacts[:apk].each do |artifact|
        assert artifact[:sha256]
        checksum_file = "#{artifact[:ci_path]}.sha256"
        assert File.exist?(checksum_file)
      end
    end
    
    it 'creates proper CI filenames' do
      manager = CIArtifactManager.new('staging', 'release')
      
      artifact = {
        name: 'app-release.apk',
        type: 'apk',
        size: 1024
      }
      
      filename = manager.send(:generate_ci_filename, artifact)
      expected = 'app-release-staging-release-123-abc123d.apk'
      
      assert_equal expected, filename
    end
    
    it 'generates artifact manifest' do
      manager = CIArtifactManager.new('development', 'debug')
      
      # First organize artifacts to create the structure
      manager.organize_artifacts
      
      manifest = manager.generate_artifact_manifest
      
      assert_equal '1.0', manifest[:version]
      assert manifest[:generated_at]
      assert_equal 'development', manifest[:environment]
      assert_equal 'debug', manifest[:build_type]
      assert_equal '123', manifest[:build_number]
      assert manifest[:artifacts]
    end
  end
  
  describe '.validate_ci_artifacts' do
    it 'validates artifact integrity' do
      # First create artifacts
      artifact_info = CIArtifactManager.organize_ci_artifacts('development', 'debug')
      
      # Should validate without errors
      CIArtifactManager.validate_ci_artifacts('development', '123')
    end
    
    it 'fails validation for missing artifacts' do
      # Create empty build directory
      build_dir = File.join('build', 'ci', 'development', '123-test')
      FileUtils.mkdir_p(build_dir)
      
      # Create manifest without actual artifacts
      manifest = {
        'artifacts' => [
          {
            'name' => 'missing.apk',
            'path' => 'apk/missing.apk',
            'size' => 1024,
            'checksum' => 'fake_checksum'
          }
        ]
      }
      
      File.write(File.join(build_dir, 'manifest.json'), JSON.pretty_generate(manifest))
      
      assert_raises(StandardError) do
        manager = CIArtifactManager.new('development', 'debug')
        manager.validate_artifact_integrity('123')
      end
    end
    
    it 'validates checksums correctly' do
      # Create artifact with known content
      build_dir = File.join('build', 'ci', 'development', '123-test')
      apk_dir = File.join(build_dir, 'apk')
      FileUtils.mkdir_p(apk_dir)
      
      content = 'test content'
      apk_path = File.join(apk_dir, 'test.apk')
      File.write(apk_path, content)
      
      expected_checksum = Digest::SHA256.hexdigest(content)
      
      # Create manifest with correct checksum
      manifest = {
        'artifacts' => [
          {
            'name' => 'test.apk',
            'path' => 'apk/test.apk',
            'size' => content.length,
            'checksum' => expected_checksum
          }
        ]
      }
      
      File.write(File.join(build_dir, 'manifest.json'), JSON.pretty_generate(manifest))
      
      # Should validate successfully
      manager = CIArtifactManager.new('development', 'debug')
      manager.send(:validate_single_artifact, build_dir, manifest['artifacts'].first)
    end
  end
  
  describe '.generate_ci_artifact_report' do
    it 'generates comprehensive artifact report' do
      # Create some test builds
      CIArtifactManager.organize_ci_artifacts('development', 'debug')
      
      report = CIArtifactManager.generate_ci_artifact_report('development')
      
      assert_equal 'development', report[:environment]
      assert report[:generated_at]
      assert report[:builds]
      assert report[:statistics]
      assert report[:storage_usage]
      
      # Check statistics
      stats = report[:statistics]
      assert stats[:total_builds]
      assert stats[:total_artifacts]
      
      # Check storage usage
      storage = report[:storage_usage]
      assert storage[:total_bytes]
      assert storage[:total_human]
    end
  end
  
  describe '.cleanup_old_ci_artifacts' do
    it 'cleans up old artifacts' do
      # Create old build directory
      old_build_dir = File.join('build', 'ci', 'development', '100-old')
      FileUtils.mkdir_p(old_build_dir)
      File.write(File.join(old_build_dir, 'test.apk'), 'old content')
      
      # Set old timestamp
      old_time = Time.now - (40 * 24 * 60 * 60) # 40 days ago
      File.utime(old_time, old_time, old_build_dir)
      
      # Create recent build directory
      recent_build_dir = File.join('build', 'ci', 'development', '123-recent')
      FileUtils.mkdir_p(recent_build_dir)
      File.write(File.join(recent_build_dir, 'test.apk'), 'recent content')
      
      # Cleanup with 30 days retention
      CIArtifactManager.cleanup_old_ci_artifacts(30)
      
      # Old directory should be removed
      refute Dir.exist?(old_build_dir)
      
      # Recent directory should remain
      assert Dir.exist?(recent_build_dir)
    end
  end
  
  describe 'GitHub Actions integration' do
    it 'creates GitHub Actions summary' do
      ENV['GITHUB_STEP_SUMMARY'] = File.join(@temp_dir, 'summary.md')
      
      manager = CIArtifactManager.new('development', 'debug')
      
      # Create artifacts and manifest
      manager.organize_artifacts
      manager.generate_artifact_manifest
      
      manager.send(:create_github_actions_summary)
      
      assert File.exist?(ENV['GITHUB_STEP_SUMMARY'])
      
      summary_content = File.read(ENV['GITHUB_STEP_SUMMARY'])
      assert_includes summary_content, '# Build Artifacts Summary'
      assert_includes summary_content, 'Environment:** development'
      assert_includes summary_content, 'Build Number:** 123'
    end
    
    it 'sets GitHub outputs' do
      ENV['GITHUB_OUTPUT'] = File.join(@temp_dir, 'outputs.txt')
      
      manager = CIArtifactManager.new('production', 'release')
      manager.send(:set_github_outputs)
      
      assert File.exist?(ENV['GITHUB_OUTPUT'])
      
      outputs = File.read(ENV['GITHUB_OUTPUT'])
      assert_includes outputs, 'environment=production'
      assert_includes outputs, 'build_type=release'
      assert_includes outputs, 'build_number=123'
    end
  end
  
  describe 'utility methods' do
    it 'formats bytes correctly' do
      assert_equal '1.0 KB', CIArtifactManager.send(:format_bytes, 1024)
      assert_equal '1.0 MB', CIArtifactManager.send(:format_bytes, 1024 * 1024)
      assert_equal '1.5 MB', CIArtifactManager.send(:format_bytes, 1024 * 1024 * 1.5)
      assert_equal '500.0 B', CIArtifactManager.send(:format_bytes, 500)
    end
    
    it 'detects CI platforms correctly' do
      manager = CIArtifactManager.new('development', 'debug')
      
      platform = manager.send(:detect_ci_platform)
      assert_equal 'github_actions', platform
      
      ENV.delete('GITHUB_ACTIONS')
      ENV['GITLAB_CI'] = 'true'
      
      platform = manager.send(:detect_ci_platform)
      assert_equal 'gitlab_ci', platform
    end
  end
end

# Run the tests
if __FILE__ == $0
  puts "Running CI Artifact Manager tests..."
  Minitest.run([])
end