require 'minitest/autorun'
require 'minitest/spec'
require 'fileutils'
require 'tmpdir'
require 'yaml'
require_relative '../version_manager'
require_relative '../config_loader'

describe VersionManager do
  before do
    # Create a temporary directory for testing
    @temp_dir = Dir.mktmpdir('version_manager_test')
    @original_dir = Dir.pwd
    
    # Create a mock project structure
    setup_mock_project
    
    # Mock environment and config
    @environment = 'development'
    @config = {
      'environment' => { 'name' => @environment },
      'app' => { 'name' => 'Test App' }
    }
    
    @version_manager = VersionManager.new(@environment, @config)
    
    # Override project root for testing
    @version_manager.instance_variable_set(:@project_root, @temp_dir)
  end

  after do
    # Cleanup
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe '#get_current_version' do
    it 'should parse version from pubspec.yaml correctly' do
      version = @version_manager.get_current_version
      
      _(version[:version_name]).must_equal '1.0.0'
      _(version[:build_number]).must_equal 1
    end

    it 'should handle version without build number' do
      # Update pubspec with version without build number
      update_pubspec_version('2.1.0')
      
      version = @version_manager.get_current_version
      
      _(version[:version_name]).must_equal '2.1.0'
      _(version[:build_number]).must_equal 1
    end

    it 'should raise error if pubspec.yaml not found' do
      FileUtils.rm(File.join(@temp_dir, 'pubspec.yaml'))
      
      _(proc { @version_manager.get_current_version }).must_raise RuntimeError
    end

    it 'should raise error if version not found in pubspec.yaml' do
      # Create pubspec without version
      File.write(File.join(@temp_dir, 'pubspec.yaml'), "name: test_app\n")
      
      _(proc { @version_manager.get_current_version }).must_raise RuntimeError
    end
  end

  describe '#increment_build_number' do
    it 'should increment build number correctly' do
      original_version = @version_manager.get_current_version
      
      # Mock UI and sh methods
      mock_ui_and_git
      
      new_build_number = @version_manager.increment_build_number
      
      _(new_build_number).must_equal original_version[:build_number] + 1
      
      # Verify files were updated
      updated_version = @version_manager.get_current_version
      _(updated_version[:build_number]).must_equal new_build_number
      _(updated_version[:version_name]).must_equal original_version[:version_name]
    end

    it 'should update all platform files' do
      mock_ui_and_git
      
      @version_manager.increment_build_number
      
      # Check pubspec.yaml was updated
      pubspec_content = File.read(File.join(@temp_dir, 'pubspec.yaml'))
      _(pubspec_content).must_match /version: 1\.0\.0\+2/
      
      # Check Android build.gradle was updated
      gradle_content = File.read(File.join(@temp_dir, 'android', 'app', 'build.gradle'))
      _(gradle_content).must_match /versionCode 2/
      
      # Check iOS Info.plist was updated
      plist_content = File.read(File.join(@temp_dir, 'ios', 'Runner', 'Info.plist'))
      _(plist_content).must_match /<string>2<\/string>/
    end
  end

  describe '#update_version_name' do
    it 'should update version name correctly' do
      mock_ui_and_git
      
      new_version = '2.1.3'
      result = @version_manager.update_version_name(new_version)
      
      _(result[:version_name]).must_equal new_version
      
      # Verify version was updated in files
      updated_version = @version_manager.get_current_version
      _(updated_version[:version_name]).must_equal new_version
    end

    it 'should reject invalid version format' do
      _(proc { @version_manager.update_version_name('invalid') }).must_raise RuntimeError
      _(proc { @version_manager.update_version_name('1.2') }).must_raise RuntimeError
      _(proc { @version_manager.update_version_name('1.2.3.4') }).must_raise RuntimeError
    end

    it 'should accept valid version formats' do
      mock_ui_and_git
      
      valid_versions = ['1.0.0', '10.20.30', '0.1.0']
      
      valid_versions.each do |version|
        @version_manager.update_version_name(version)
        updated_version = @version_manager.get_current_version
        _(updated_version[:version_name]).must_equal version
      end
    end
  end

  describe '#increment_patch' do
    it 'should increment patch version correctly' do
      mock_ui_and_git
      
      result = @version_manager.increment_patch
      
      _(result[:version_name]).must_equal '1.0.1'
      
      # Test multiple increments
      @version_manager.increment_patch
      updated_version = @version_manager.get_current_version
      _(updated_version[:version_name]).must_equal '1.0.2'
    end
  end

  describe '#increment_minor' do
    it 'should increment minor version and reset patch' do
      mock_ui_and_git
      
      # First increment patch to make it non-zero
      @version_manager.increment_patch
      
      # Then increment minor
      result = @version_manager.increment_minor
      
      _(result[:version_name]).must_equal '1.1.0'
    end
  end

  describe '#increment_major' do
    it 'should increment major version and reset minor and patch' do
      mock_ui_and_git
      
      # First increment minor and patch
      @version_manager.increment_minor
      @version_manager.increment_patch
      
      # Then increment major
      result = @version_manager.increment_major
      
      _(result[:version_name]).must_equal '2.0.0'
    end
  end

  describe '#create_tag' do
    it 'should create git tag with correct format' do
      mock_ui_and_git
      
      # Mock git commands
      git_commands = []
      @version_manager.define_singleton_method(:sh) do |command|
        git_commands << command
        case command
        when /git rev-parse --git-dir/
          # Simulate being in a git repository
          ''
        when /git tag/
          # Simulate successful tag creation
          ''
        when /git push/
          # Simulate successful push
          ''
        end
      end
      
      tag_name = @version_manager.create_tag('Test release')
      
      _(tag_name).must_equal 'v1.0.0'
      _(git_commands).must_include 'git tag -a v1.0.0 -m "Test release"'
      _(git_commands).must_include 'git push origin v1.0.0'
    end

    it 'should handle git errors gracefully' do
      mock_ui_and_git
      
      # Mock git command to fail
      @version_manager.define_singleton_method(:sh) do |command|
        raise StandardError.new('Git command failed')
      end
      
      _(proc { @version_manager.create_tag }).must_raise StandardError
    end
  end

  describe 'version validation' do
    it 'should validate version format correctly' do
      # Access private method for testing
      validator = @version_manager.method(:valid_version_format?)
      
      # Valid formats
      _( validator.call('1.0.0') ).must_equal true
      _( validator.call('10.20.30') ).must_equal true
      _( validator.call('0.1.0') ).must_equal true
      
      # Invalid formats
      _( validator.call('1.0') ).must_equal false
      _( validator.call('1.0.0.1') ).must_equal false
      _( validator.call('v1.0.0') ).must_equal false
      _( validator.call('1.0.0-beta') ).must_equal false
      _( validator.call('invalid') ).must_equal false
    end
  end

  describe 'file updates' do
    it 'should handle missing platform files gracefully' do
      # Remove Android files
      FileUtils.rm_rf(File.join(@temp_dir, 'android'))
      
      # Remove iOS files
      FileUtils.rm_rf(File.join(@temp_dir, 'ios'))
      
      mock_ui_and_git
      
      # Should not raise error
      @version_manager.increment_build_number
      
      # pubspec.yaml should still be updated
      updated_version = @version_manager.get_current_version
      _(updated_version[:build_number]).must_equal 2
    end

    it 'should preserve file formatting' do
      mock_ui_and_git
      
      # Add some comments to pubspec.yaml
      original_content = File.read(File.join(@temp_dir, 'pubspec.yaml'))
      modified_content = "# This is a comment\n" + original_content + "\n# End comment"
      File.write(File.join(@temp_dir, 'pubspec.yaml'), modified_content)
      
      @version_manager.increment_build_number
      
      # Check that comments are preserved
      updated_content = File.read(File.join(@temp_dir, 'pubspec.yaml'))
      _(updated_content).must_match /# This is a comment/
      _(updated_content).must_match /# End comment/
      _(updated_content).must_match /version: 1\.0\.0\+2/
    end
  end

  describe 'git integration' do
    it 'should handle non-git repository gracefully' do
      mock_ui_and_git
      
      # Mock git command to fail (not a git repository)
      @version_manager.define_singleton_method(:sh) do |command|
        if command.include?('git')
          raise StandardError.new('Not a git repository')
        end
      end
      
      # Should not raise error, just log warning
      @version_manager.increment_build_number
    end

    it 'should commit version changes with correct message' do
      mock_ui_and_git
      
      git_commands = []
      @version_manager.define_singleton_method(:sh) do |command|
        git_commands << command
        '' # Return empty string for all commands
      end
      
      @version_manager.increment_build_number
      
      # Check that correct files were added
      _(git_commands).must_include 'git add pubspec.yaml'
      _(git_commands).must_include 'git add android/app/build.gradle'
      _(git_commands).must_include 'git add ios/Runner/Info.plist'
      
      # Check commit message
      commit_command = git_commands.find { |cmd| cmd.include?('git commit') }
      _(commit_command).must_match /chore: increment build number to 2/
    end
  end

  private

  def setup_mock_project
    # Create pubspec.yaml
    pubspec_content = <<~YAML
      name: test_app
      description: A test Flutter app
      version: 1.0.0+1
      
      environment:
        sdk: ">=3.0.0 <4.0.0"
      
      dependencies:
        flutter:
          sdk: flutter
    YAML
    
    File.write(File.join(@temp_dir, 'pubspec.yaml'), pubspec_content)
    
    # Create Android build.gradle
    FileUtils.mkdir_p(File.join(@temp_dir, 'android', 'app'))
    gradle_content = <<~GRADLE
      android {
          compileSdkVersion 33
          
          defaultConfig {
              applicationId "com.example.test"
              minSdkVersion 21
              targetSdkVersion 33
              versionCode 1
              versionName "1.0.0"
          }
      }
    GRADLE
    
    File.write(File.join(@temp_dir, 'android', 'app', 'build.gradle'), gradle_content)
    
    # Create iOS Info.plist
    FileUtils.mkdir_p(File.join(@temp_dir, 'ios', 'Runner'))
    plist_content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      	<key>CFBundleShortVersionString</key>
      	<string>1.0.0</string>
      	<key>CFBundleVersion</key>
      	<string>1</string>
      </dict>
      </plist>
    PLIST
    
    File.write(File.join(@temp_dir, 'ios', 'Runner', 'Info.plist'), plist_content)
  end

  def update_pubspec_version(version)
    pubspec_path = File.join(@temp_dir, 'pubspec.yaml')
    content = File.read(pubspec_path)
    updated_content = content.gsub(/version: .*/, "version: #{version}")
    File.write(pubspec_path, updated_content)
  end

  def mock_ui_and_git
    # Mock UI methods
    @version_manager.define_singleton_method(:UI) do
      OpenStruct.new(
        header: proc { |msg| puts "HEADER: #{msg}" },
        message: proc { |msg| puts "MESSAGE: #{msg}" },
        success: proc { |msg| puts "SUCCESS: #{msg}" },
        error: proc { |msg| puts "ERROR: #{msg}" },
        user_error!: proc { |msg| raise RuntimeError.new(msg) }
      )
    end
    
    # Mock sh method for git commands
    @version_manager.define_singleton_method(:sh) do |command|
      puts "COMMAND: #{command}"
      case command
      when /git rev-parse --git-dir/
        '' # Simulate being in a git repository
      when /git rev-parse HEAD/
        'abc123def456' # Mock commit hash
      when /git rev-parse --abbrev-ref HEAD/
        'main' # Mock branch name
      else
        '' # Default return for other commands
      end
    end
  end
end