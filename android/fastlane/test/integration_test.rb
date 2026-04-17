require 'minitest/autorun'
require 'minitest/spec'
require 'fileutils'
require 'tmpdir'
require 'yaml'
require_relative '../version_manager'
require_relative '../config_loader'

describe 'Version Manager Integration Tests' do
  before do
    # Create a temporary directory for integration testing
    @temp_dir = Dir.mktmpdir('version_manager_integration_test')
    @original_dir = Dir.pwd
    
    # Create a realistic project structure
    setup_realistic_project
    
    # Mock environment and config
    @environment = 'development'
    @config = load_test_config
    
    @version_manager = VersionManager.new(@environment, @config)
    
    # Override project root for testing
    @version_manager.instance_variable_set(:@project_root, @temp_dir)
    
    # Mock external dependencies
    mock_external_dependencies
  end

  after do
    # Cleanup
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  describe 'End-to-End Version Management Workflow' do
    it 'should handle complete release workflow' do
      # Initial state
      initial_version = @version_manager.get_current_version
      _(initial_version[:version_name]).must_equal '1.0.0'
      _(initial_version[:build_number]).must_equal 1
      
      # Increment build number for development builds
      @version_manager.increment_build_number
      dev_version = @version_manager.get_current_version
      _(dev_version[:build_number]).must_equal 2
      
      # Increment patch for bug fix release
      @version_manager.increment_patch
      patch_version = @version_manager.get_current_version
      _(patch_version[:version_name]).must_equal '1.0.1'
      
      # Increment minor for feature release
      @version_manager.increment_minor
      minor_version = @version_manager.get_current_version
      _(minor_version[:version_name]).must_equal '1.1.0'
      
      # Increment major for breaking changes
      @version_manager.increment_major
      major_version = @version_manager.get_current_version
      _(major_version[:version_name]).must_equal '2.0.0'
      
      # Create release tag
      tag_name = @version_manager.create_tag('Major release v2.0.0')
      _(tag_name).must_equal 'v2.0.0'
    end

    it 'should maintain consistency across all platform files' do
      # Update to a specific version
      @version_manager.update_version_name('3.2.1')
      @version_manager.increment_build_number
      
      final_version = @version_manager.get_current_version
      
      # Check pubspec.yaml
      pubspec_content = File.read(File.join(@temp_dir, 'pubspec.yaml'))
      _(pubspec_content).must_match /version: 3\.2\.1\+2/
      
      # Check Android build.gradle
      gradle_content = File.read(File.join(@temp_dir, 'android', 'app', 'build.gradle'))
      _(gradle_content).must_match /versionCode 2/
      _(gradle_content).must_match /versionName "3\.2\.1"/
      
      # Check iOS Info.plist
      plist_content = File.read(File.join(@temp_dir, 'ios', 'Runner', 'Info.plist'))
      _(plist_content).must_match /<string>3\.2\.1<\/string>/
      _(plist_content).must_match /<string>2<\/string>/
    end

    it 'should handle rapid version increments correctly' do
      # Simulate multiple rapid builds
      10.times do |i|
        @version_manager.increment_build_number
        version = @version_manager.get_current_version
        _(version[:build_number]).must_equal i + 2 # Starting from 1, so +2 after first increment
      end
      
      final_version = @version_manager.get_current_version
      _(final_version[:build_number]).must_equal 11
      _(final_version[:version_name]).must_equal '1.0.0'
    end

    it 'should handle version rollback scenario' do
      # Increment to a higher version
      @version_manager.update_version_name('2.5.3')
      @version_manager.increment_build_number
      
      # Rollback to previous version (simulate hotfix)
      @version_manager.update_version_name('2.5.2')
      @version_manager.increment_build_number
      
      final_version = @version_manager.get_current_version
      _(final_version[:version_name]).must_equal '2.5.2'
      _(final_version[:build_number]).must_equal 3
    end
  end

  describe 'Error Recovery and Edge Cases' do
    it 'should recover from corrupted pubspec.yaml' do
      # Corrupt the pubspec.yaml
      File.write(File.join(@temp_dir, 'pubspec.yaml'), 'invalid yaml content [')
      
      _(proc { @version_manager.get_current_version }).must_raise RuntimeError
    end

    it 'should handle missing platform-specific files' do
      # Remove Android files
      FileUtils.rm_rf(File.join(@temp_dir, 'android'))
      
      # Should still work for other platforms
      @version_manager.increment_build_number
      
      version = @version_manager.get_current_version
      _(version[:build_number]).must_equal 2
      
      # iOS should still be updated
      plist_content = File.read(File.join(@temp_dir, 'ios', 'Runner', 'Info.plist'))
      _(plist_content).must_match /<string>2<\/string>/
    end

    it 'should handle concurrent version updates' do
      # Simulate concurrent updates by modifying files externally
      external_version = '5.0.0+10'
      update_pubspec_version(external_version)
      
      # Version manager should read the updated version
      current_version = @version_manager.get_current_version
      _(current_version[:version_name]).must_equal '5.0.0'
      _(current_version[:build_number]).must_equal 10
      
      # Increment should work from the current state
      @version_manager.increment_build_number
      updated_version = @version_manager.get_current_version
      _(updated_version[:build_number]).must_equal 11
    end
  end

  describe 'Git Integration' do
    it 'should handle git operations correctly' do
      git_commands = []
      
      # Override sh method to capture git commands
      @version_manager.define_singleton_method(:sh) do |command|
        git_commands << command
        case command
        when /git rev-parse --git-dir/
          '' # Simulate git repository
        when /git rev-parse HEAD/
          'abc123def456789'
        when /git rev-parse --abbrev-ref HEAD/
          'feature/version-management'
        when /git tag/
          '' # Simulate successful tag creation
        when /git push/
          '' # Simulate successful push
        else
          ''
        end
      end
      
      # Perform version operations
      @version_manager.increment_build_number
      @version_manager.create_tag('Test tag')
      
      # Verify git commands were called
      _(git_commands).must_include 'git add pubspec.yaml'
      _(git_commands).must_include 'git add android/app/build.gradle'
      _(git_commands).must_include 'git add ios/Runner/Info.plist'
      
      commit_command = git_commands.find { |cmd| cmd.include?('git commit') }
      _(commit_command).wont_be_nil
      _(commit_command).must_match /chore: increment build number to 2/
      
      tag_command = git_commands.find { |cmd| cmd.include?('git tag') }
      _(tag_command).wont_be_nil
      _(tag_command).must_match /git tag -a v1\.0\.0 -m "Test tag"/
    end

    it 'should handle git failures gracefully' do
      # Mock git to fail
      @version_manager.define_singleton_method(:sh) do |command|
        if command.include?('git')
          raise StandardError.new('Git operation failed')
        end
      end
      
      # Version increment should still work (just without git operations)
      @version_manager.increment_build_number
      
      version = @version_manager.get_current_version
      _(version[:build_number]).must_equal 2
      
      # Tag creation should fail
      _(proc { @version_manager.create_tag }).must_raise StandardError
    end
  end

  describe 'Performance and Reliability' do
    it 'should handle large version numbers' do
      # Test with large version numbers
      large_version = '999.888.777+123456'
      update_pubspec_version(large_version)
      
      version = @version_manager.get_current_version
      _(version[:version_name]).must_equal '999.888.777'
      _(version[:build_number]).must_equal 123456
      
      # Increment should work correctly
      @version_manager.increment_build_number
      updated_version = @version_manager.get_current_version
      _(updated_version[:build_number]).must_equal 123457
    end

    it 'should be idempotent for version reads' do
      # Multiple reads should return the same result
      version1 = @version_manager.get_current_version
      version2 = @version_manager.get_current_version
      version3 = @version_manager.get_current_version
      
      _(version1).must_equal version2
      _(version2).must_equal version3
    end

    it 'should handle file system permissions' do
      # Make pubspec.yaml read-only
      pubspec_path = File.join(@temp_dir, 'pubspec.yaml')
      File.chmod(0444, pubspec_path)
      
      # Should raise error when trying to update
      _(proc { @version_manager.increment_build_number }).must_raise Errno::EACCES
      
      # Restore permissions for cleanup
      File.chmod(0644, pubspec_path)
    end
  end

  private

  def setup_realistic_project
    # Create a more realistic Flutter project structure
    
    # pubspec.yaml with dependencies
    pubspec_content = <<~YAML
      name: cms_mobile_app
      description: CMS Mobile Application for Business Management
      
      version: 1.0.0+1
      
      environment:
        sdk: ">=3.0.6 <4.0.0"
      
      dependencies:
        flutter:
          sdk: flutter
        cupertino_icons: ^1.0.2
        dio: ^5.3.2
        mobx: ^2.2.0
        flutter_mobx: ^2.0.6+5
        get_it: ^7.6.4
        go_router: ^12.1.1
        
      dev_dependencies:
        flutter_test:
          sdk: flutter
        build_runner: ^2.4.7
        mobx_codegen: ^2.4.0
        json_annotation: ^4.8.1
        json_serializable: ^6.7.1
        
      flutter:
        uses-material-design: true
        assets:
          - assets/images/
          - assets/icons/
    YAML
    
    File.write(File.join(@temp_dir, 'pubspec.yaml'), pubspec_content)
    
    # Android build.gradle with more realistic content
    FileUtils.mkdir_p(File.join(@temp_dir, 'android', 'app'))
    gradle_content = <<~GRADLE
      def localProperties = new Properties()
      def localPropertiesFile = rootProject.file('local.properties')
      if (localPropertiesFile.exists()) {
          localPropertiesFile.withReader('UTF-8') { reader ->
              localProperties.load(reader)
          }
      }
      
      def flutterRoot = localProperties.getProperty('flutter.sdk')
      if (flutterRoot == null) {
          throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
      }
      
      def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
      if (flutterVersionCode == null) {
          flutterVersionCode = '1'
      }
      
      def flutterVersionName = localProperties.getProperty('flutter.versionName')
      if (flutterVersionName == null) {
          flutterVersionName = '1.0'
      }
      
      apply plugin: 'com.android.application'
      apply plugin: 'kotlin-android'
      apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
      
      android {
          compileSdkVersion 34
          ndkVersion flutter.ndkVersion
      
          compileOptions {
              sourceCompatibility JavaVersion.VERSION_1_8
              targetCompatibility JavaVersion.VERSION_1_8
          }
      
          kotlinOptions {
              jvmTarget = '1.8'
          }
      
          sourceSets {
              main.java.srcDirs += 'src/main/kotlin'
          }
      
          defaultConfig {
              applicationId "com.example.cms_mobile"
              minSdkVersion 21
              targetSdkVersion 34
              versionCode 1
              versionName "1.0.0"
          }
      
          buildTypes {
              release {
                  signingConfig signingConfigs.debug
              }
          }
      }
      
      flutter {
          source '../..'
      }
      
      dependencies {
          implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
      }
    GRADLE
    
    File.write(File.join(@temp_dir, 'android', 'app', 'build.gradle'), gradle_content)
    
    # iOS Info.plist with more realistic content
    FileUtils.mkdir_p(File.join(@temp_dir, 'ios', 'Runner'))
    plist_content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      	<key>CFBundleDevelopmentRegion</key>
      	<string>$(DEVELOPMENT_LANGUAGE)</string>
      	<key>CFBundleDisplayName</key>
      	<string>CMS Mobile</string>
      	<key>CFBundleExecutable</key>
      	<string>$(EXECUTABLE_NAME)</string>
      	<key>CFBundleIdentifier</key>
      	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
      	<key>CFBundleInfoDictionaryVersion</key>
      	<string>6.0</string>
      	<key>CFBundleName</key>
      	<string>cms_mobile</string>
      	<key>CFBundlePackageType</key>
      	<string>APPL</string>
      	<key>CFBundleShortVersionString</key>
      	<string>1.0.0</string>
      	<key>CFBundleSignature</key>
      	<string>????</string>
      	<key>CFBundleVersion</key>
      	<string>1</string>
      	<key>LSRequiresIPhoneOS</key>
      	<true/>
      	<key>UILaunchStoryboardName</key>
      	<string>LaunchScreen</string>
      	<key>UIMainStoryboardFile</key>
      	<string>Main</string>
      	<key>UISupportedInterfaceOrientations</key>
      	<array>
      		<string>UIInterfaceOrientationPortrait</string>
      		<string>UIInterfaceOrientationLandscapeLeft</string>
      		<string>UIInterfaceOrientationLandscapeRight</string>
      	</array>
      	<key>UISupportedInterfaceOrientations~ipad</key>
      	<array>
      		<string>UIInterfaceOrientationPortrait</string>
      		<string>UIInterfaceOrientationPortraitUpsideDown</string>
      		<string>UIInterfaceOrientationLandscapeLeft</string>
      		<string>UIInterfaceOrientationLandscapeRight</string>
      	</array>
      	<key>UIViewControllerBasedStatusBarAppearance</key>
      	<false/>
      	<key>CADisableMinimumFrameDurationOnPhone</key>
      	<true/>
      	<key>UIApplicationSupportsIndirectInputEvents</key>
      	<true/>
      </dict>
      </plist>
    PLIST
    
    File.write(File.join(@temp_dir, 'ios', 'Runner', 'Info.plist'), plist_content)
  end

  def load_test_config
    {
      'environment' => {
        'name' => 'development',
        'display_name' => 'Development'
      },
      'app' => {
        'name' => 'CMS Mobile Dev',
        'bundle_id' => 'com.example.cms_mobile.dev'
      },
      'network' => {
        'api_base_url' => 'https://dev-api.example.com',
        'websocket_url' => 'wss://dev-ws.example.com'
      }
    }
  end

  def update_pubspec_version(version)
    pubspec_path = File.join(@temp_dir, 'pubspec.yaml')
    content = File.read(pubspec_path)
    updated_content = content.gsub(/version: .*/, "version: #{version}")
    File.write(pubspec_path, updated_content)
  end

  def mock_external_dependencies
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
        'abc123def456789012345678901234567890abcd' # Mock full commit hash
      when /git rev-parse --abbrev-ref HEAD/
        'main' # Mock branch name
      else
        '' # Default return for other commands
      end
    end
  end
end