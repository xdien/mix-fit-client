# Debug Tools for Fastlane Environment Configuration
# Provides debugging utilities for configuration and build issues

require 'json'
require 'yaml'
require 'fileutils'
require 'digest'
require 'open3'

class DebugTools
  def self.diagnose_environment(environment = 'development')
    UI.header("🔍 Diagnosing #{environment} environment")
    
    diagnosis = {
      environment: environment,
      timestamp: Time.now.iso8601,
      checks: {},
      issues: [],
      recommendations: []
    }
    
    # Check configuration files
    diagnosis[:checks][:configuration] = check_configuration(environment, diagnosis)
    
    # Check signing setup
    diagnosis[:checks][:signing] = check_signing_setup(environment, diagnosis)
    
    # Check build environment
    diagnosis[:checks][:build_environment] = check_build_environment(diagnosis)
    
    # Check dependencies
    diagnosis[:checks][:dependencies] = check_dependencies(diagnosis)
    
    # Check file permissions
    diagnosis[:checks][:permissions] = check_file_permissions(diagnosis)
    
    # Check network connectivity
    diagnosis[:checks][:network] = check_network_connectivity(environment, diagnosis)
    
    # Generate diagnosis report
    generate_diagnosis_report(diagnosis)
    
    # Display summary
    display_diagnosis_summary(diagnosis)
    
    diagnosis
  end
  
  def self.validate_build_environment
    UI.header("🔧 Validating build environment")
    
    validation = {
      timestamp: Time.now.iso8601,
      system_info: get_detailed_system_info,
      tools: {},
      issues: [],
      recommendations: []
    }
    
    # Check Flutter installation
    validation[:tools][:flutter] = check_flutter_installation(validation)
    
    # Check Android SDK
    validation[:tools][:android_sdk] = check_android_sdk(validation)
    
    # Check Java/JDK
    validation[:tools][:java] = check_java_installation(validation)
    
    # Check Gradle
    validation[:tools][:gradle] = check_gradle_installation(validation)
    
    # Check Git
    validation[:tools][:git] = check_git_installation(validation)
    
    # Check Ruby and Fastlane
    validation[:tools][:ruby] = check_ruby_installation(validation)
    validation[:tools][:fastlane] = check_fastlane_installation(validation)
    
    # Generate validation report
    generate_validation_report(validation)
    
    # Display summary
    display_validation_summary(validation)
    
    validation
  end
  
  def self.analyze_build_failure(log_file = nil)
    UI.header("🔍 Analyzing build failure")
    
    # Find the most recent build log if not specified
    if log_file.nil?
      log_dir = File.join(Dir.pwd, '..', '..', 'build', 'build_logs')
      if Dir.exist?(log_dir)
        log_files = Dir.glob(File.join(log_dir, '*.log')).sort_by { |f| File.mtime(f) }
        log_file = log_files.last
      end
    end
    
    unless log_file && File.exist?(log_file)
      UI.error("No build log file found for analysis")
      return nil
    end
    
    analysis = {
      log_file: log_file,
      timestamp: Time.now.iso8601,
      file_size: File.size(log_file),
      errors: [],
      warnings: [],
      patterns: {},
      suggestions: []
    }
    
    # Analyze log content
    analyze_log_content(log_file, analysis)
    
    # Generate analysis report
    generate_analysis_report(analysis)
    
    # Display summary
    display_analysis_summary(analysis)
    
    analysis
  end
  
  def self.check_configuration_integrity(environment = 'development')
    UI.header("🔍 Checking configuration integrity for #{environment}")
    
    config_path = File.join(Dir.pwd, '..', '..', 'config', 'environments', "#{environment}.yaml")
    
    integrity = {
      environment: environment,
      config_path: config_path,
      timestamp: Time.now.iso8601,
      file_info: {},
      validation: {},
      schema_compliance: {},
      issues: [],
      recommendations: []
    }
    
    # Check file existence and basic info
    if File.exist?(config_path)
      integrity[:file_info] = {
        exists: true,
        size: File.size(config_path),
        modified: File.mtime(config_path).iso8601,
        readable: File.readable?(config_path),
        checksum: Digest::SHA256.hexdigest(File.read(config_path))
      }
      
      # Parse and validate configuration
      begin
        config = YAML.load_file(config_path)
        integrity[:validation][:parse_success] = true
        integrity[:validation][:config_keys] = config.keys
        
        # Detailed validation
        validate_config_structure(config, integrity)
        validate_config_values(config, integrity)
        check_config_security(config, integrity)
        
      rescue => e
        integrity[:validation][:parse_success] = false
        integrity[:validation][:parse_error] = e.message
        integrity[:issues] << {
          type: 'parse_error',
          message: "Failed to parse configuration file: #{e.message}",
          severity: 'high'
        }
      end
    else
      integrity[:file_info][:exists] = false
      integrity[:issues] << {
        type: 'missing_file',
        message: "Configuration file not found: #{config_path}",
        severity: 'high'
      }
    end
    
    # Generate integrity report
    generate_integrity_report(integrity)
    
    # Display summary
    display_integrity_summary(integrity)
    
    integrity
  end
  
  def self.test_signing_configuration(environment = 'development')
    UI.header("🔐 Testing signing configuration for #{environment}")
    
    test_result = {
      environment: environment,
      timestamp: Time.now.iso8601,
      keystore_tests: {},
      certificate_tests: {},
      environment_tests: {},
      issues: [],
      recommendations: []
    }
    
    begin
      # Load configuration
      config = ConfigLoader.load_environment_config(environment)
      signing_config = config['signing']
      
      # Test keystore file
      test_keystore_file(signing_config, test_result)
      
      # Test environment variables
      test_signing_environment_variables(signing_config, test_result)
      
      # Test certificate validity
      test_certificate_validity(signing_config, test_result)
      
      # Test signing process
      test_signing_process(signing_config, test_result)
      
    rescue => e
      test_result[:issues] << {
        type: 'configuration_error',
        message: "Failed to load signing configuration: #{e.message}",
        severity: 'high'
      }
    end
    
    # Generate test report
    generate_signing_test_report(test_result)
    
    # Display summary
    display_signing_test_summary(test_result)
    
    test_result
  end
  
  def self.generate_debug_package(environment = 'development')
    UI.header("📦 Generating debug package for #{environment}")
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    debug_dir = File.join(Dir.pwd, '..', '..', 'build', 'debug_packages')
    package_dir = File.join(debug_dir, "debug_package_#{environment}_#{timestamp}")
    
    FileUtils.mkdir_p(package_dir)
    
    package_info = {
      environment: environment,
      timestamp: Time.now.iso8601,
      package_dir: package_dir,
      included_files: [],
      reports: []
    }
    
    begin
      # Include configuration files
      copy_config_files(environment, package_dir, package_info)
      
      # Include recent logs
      copy_recent_logs(package_dir, package_info)
      
      # Include system information
      generate_system_info_report(package_dir, package_info)
      
      # Run diagnostics
      diagnosis = diagnose_environment(environment)
      diagnosis_file = File.join(package_dir, 'environment_diagnosis.json')
      File.write(diagnosis_file, JSON.pretty_generate(diagnosis))
      package_info[:reports] << 'environment_diagnosis.json'
      
      # Run build environment validation
      validation = validate_build_environment
      validation_file = File.join(package_dir, 'build_environment_validation.json')
      File.write(validation_file, JSON.pretty_generate(validation))
      package_info[:reports] << 'build_environment_validation.json'
      
      # Check configuration integrity
      integrity = check_configuration_integrity(environment)
      integrity_file = File.join(package_dir, 'configuration_integrity.json')
      File.write(integrity_file, JSON.pretty_generate(integrity))
      package_info[:reports] << 'configuration_integrity.json'
      
      # Create package manifest
      manifest_file = File.join(package_dir, 'package_manifest.json')
      File.write(manifest_file, JSON.pretty_generate(package_info))
      
      # Create README
      create_debug_package_readme(package_dir, package_info)
      
      UI.success("✅ Debug package created: #{package_dir}")
      
    rescue => e
      UI.error("❌ Failed to create debug package: #{e.message}")
      raise e
    end
    
    package_info
  end
  
  private
  
  def self.check_configuration(environment, diagnosis)
    config_path = File.join(Dir.pwd, '..', '..', 'config', 'environments', "#{environment}.yaml")
    
    check_result = {
      config_file_exists: File.exist?(config_path),
      config_file_path: config_path
    }
    
    if check_result[:config_file_exists]
      check_result[:config_file_size] = File.size(config_path)
      check_result[:config_file_modified] = File.mtime(config_path).iso8601
      
      begin
        config = YAML.load_file(config_path)
        check_result[:config_parse_success] = true
        check_result[:config_sections] = config.keys
        
        # Check required sections
        required_sections = %w[environment app network build signing]
        missing_sections = required_sections - config.keys
        
        if missing_sections.any?
          check_result[:missing_sections] = missing_sections
          diagnosis[:issues] << {
            type: 'configuration',
            message: "Missing configuration sections: #{missing_sections.join(', ')}",
            severity: 'high'
          }
        end
        
      rescue => e
        check_result[:config_parse_success] = false
        check_result[:config_parse_error] = e.message
        diagnosis[:issues] << {
          type: 'configuration',
          message: "Failed to parse configuration file: #{e.message}",
          severity: 'high'
        }
      end
    else
      diagnosis[:issues] << {
        type: 'configuration',
        message: "Configuration file not found: #{config_path}",
        severity: 'high'
      }
      diagnosis[:recommendations] << "Create configuration file for #{environment} environment"
    end
    
    check_result
  end
  
  def self.check_signing_setup(environment, diagnosis)
    check_result = {}
    
    begin
      config = ConfigLoader.load_environment_config(environment)
      signing_config = config['signing']
      
      # Check keystore file
      keystore_path = File.join(Dir.pwd, '..', 'keystores', signing_config['store_file'])
      check_result[:keystore_exists] = File.exist?(keystore_path)
      check_result[:keystore_path] = keystore_path
      
      unless check_result[:keystore_exists]
        diagnosis[:issues] << {
          type: 'signing',
          message: "Keystore file not found: #{keystore_path}",
          severity: 'high'
        }
        diagnosis[:recommendations] << "Create or copy keystore file to #{keystore_path}"
      end
      
      # Check environment variables
      required_env_vars = [
        signing_config['store_password_env'],
        signing_config['key_password_env']
      ]
      
      missing_env_vars = required_env_vars.select { |var| ENV[var].nil? || ENV[var].empty? }
      check_result[:missing_env_vars] = missing_env_vars
      
      if missing_env_vars.any?
        diagnosis[:issues] << {
          type: 'signing',
          message: "Missing environment variables: #{missing_env_vars.join(', ')}",
          severity: 'medium'
        }
        diagnosis[:recommendations] << "Set required environment variables for signing"
      end
      
    rescue => e
      check_result[:error] = e.message
      diagnosis[:issues] << {
        type: 'signing',
        message: "Failed to check signing setup: #{e.message}",
        severity: 'high'
      }
    end
    
    check_result
  end
  
  def self.check_build_environment(diagnosis)
    check_result = {}
    
    # Check Flutter
    flutter_version = `flutter --version 2>/dev/null`.strip rescue nil
    check_result[:flutter_available] = !flutter_version.nil?
    check_result[:flutter_version] = flutter_version
    
    unless check_result[:flutter_available]
      diagnosis[:issues] << {
        type: 'build_environment',
        message: "Flutter not found in PATH",
        severity: 'high'
      }
      diagnosis[:recommendations] << "Install Flutter and add to PATH"
    end
    
    # Check Android SDK
    android_home = ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT']
    check_result[:android_sdk_path] = android_home
    check_result[:android_sdk_available] = !android_home.nil? && Dir.exist?(android_home)
    
    unless check_result[:android_sdk_available]
      diagnosis[:issues] << {
        type: 'build_environment',
        message: "Android SDK not found",
        severity: 'high'
      }
      diagnosis[:recommendations] << "Install Android SDK and set ANDROID_HOME environment variable"
    end
    
    # Check Java
    java_version = `java -version 2>&1`.strip rescue nil
    check_result[:java_available] = !java_version.nil?
    check_result[:java_version] = java_version
    
    unless check_result[:java_available]
      diagnosis[:issues] << {
        type: 'build_environment',
        message: "Java not found",
        severity: 'high'
      }
      diagnosis[:recommendations] << "Install Java JDK"
    end
    
    check_result
  end
  
  def self.check_dependencies(diagnosis)
    check_result = {}
    
    # Check pubspec.yaml
    pubspec_path = File.join(Dir.pwd, '..', '..', 'pubspec.yaml')
    check_result[:pubspec_exists] = File.exist?(pubspec_path)
    
    if check_result[:pubspec_exists]
      # Check if dependencies are installed
      packages_path = File.join(Dir.pwd, '..', '..', '.packages')
      check_result[:packages_exists] = File.exist?(packages_path)
      
      unless check_result[:packages_exists]
        diagnosis[:issues] << {
          type: 'dependencies',
          message: "Flutter dependencies not installed",
          severity: 'medium'
        }
        diagnosis[:recommendations] << "Run 'flutter pub get' to install dependencies"
      end
    else
      diagnosis[:issues] << {
        type: 'dependencies',
        message: "pubspec.yaml not found",
        severity: 'high'
      }
    end
    
    # Check Gemfile
    gemfile_path = File.join(Dir.pwd, '..', 'Gemfile')
    check_result[:gemfile_exists] = File.exist?(gemfile_path)
    
    if check_result[:gemfile_exists]
      # Check if gems are installed
      gemfile_lock_path = File.join(Dir.pwd, '..', 'Gemfile.lock')
      check_result[:gemfile_lock_exists] = File.exist?(gemfile_lock_path)
      
      unless check_result[:gemfile_lock_exists]
        diagnosis[:recommendations] << "Run 'bundle install' to install Ruby gems"
      end
    end
    
    check_result
  end
  
  def self.check_file_permissions(diagnosis)
    check_result = {}
    
    # Check key directories
    directories_to_check = [
      File.join(Dir.pwd, '..', '..', 'build'),
      File.join(Dir.pwd, '..', 'keystores'),
      File.join(Dir.pwd, '..', '..', 'config')
    ]
    
    directories_to_check.each do |dir|
      dir_name = File.basename(dir)
      if Dir.exist?(dir)
        check_result["#{dir_name}_readable"] = File.readable?(dir)
        check_result["#{dir_name}_writable"] = File.writable?(dir)
        
        unless File.writable?(dir)
          diagnosis[:issues] << {
            type: 'permissions',
            message: "Directory not writable: #{dir}",
            severity: 'medium'
          }
        end
      else
        check_result["#{dir_name}_exists"] = false
      end
    end
    
    check_result
  end
  
  def self.check_network_connectivity(environment, diagnosis)
    check_result = {}
    
    begin
      config = ConfigLoader.load_environment_config(environment)
      api_url = config['network']['api_base_url']
      
      if api_url
        # Simple connectivity check
        uri = URI.parse(api_url)
        check_result[:api_host] = uri.host
        check_result[:api_port] = uri.port
        
        # Try to resolve hostname
        begin
          require 'resolv'
          ip = Resolv.getaddress(uri.host)
          check_result[:dns_resolution] = true
          check_result[:resolved_ip] = ip
        rescue => e
          check_result[:dns_resolution] = false
          diagnosis[:issues] << {
            type: 'network',
            message: "Cannot resolve hostname: #{uri.host}",
            severity: 'medium'
          }
        end
      end
    rescue => e
      check_result[:error] = e.message
    end
    
    check_result
  end
  
  def self.get_detailed_system_info
    {
      ruby_version: RUBY_VERSION,
      ruby_platform: RUBY_PLATFORM,
      fastlane_version: Fastlane::VERSION,
      hostname: Socket.gethostname,
      user: ENV['USER'] || ENV['USERNAME'],
      home_directory: ENV['HOME'] || ENV['USERPROFILE'],
      working_directory: Dir.pwd,
      path_env: ENV['PATH'],
      shell: ENV['SHELL'],
      ci_environment: ENV['CI'] == 'true',
      github_actions: ENV['GITHUB_ACTIONS'] == 'true',
      jenkins: !ENV['JENKINS_URL'].nil?
    }
  end
  
  def self.check_flutter_installation(validation)
    result = {}
    
    begin
      output, status = Open3.capture2e('flutter --version')
      result[:available] = status.success?
      result[:version_output] = output.strip
      
      if status.success?
        # Parse version information
        lines = output.lines
        flutter_line = lines.find { |line| line.include?('Flutter') }
        dart_line = lines.find { |line| line.include?('Dart') }
        
        result[:flutter_version] = flutter_line.strip if flutter_line
        result[:dart_version] = dart_line.strip if dart_line
      else
        validation[:issues] << {
          type: 'flutter',
          message: "Flutter command failed: #{output}",
          severity: 'high'
        }
      end
    rescue => e
      result[:available] = false
      result[:error] = e.message
      validation[:issues] << {
        type: 'flutter',
        message: "Flutter not found: #{e.message}",
        severity: 'high'
      }
    end
    
    result
  end
  
  def self.check_android_sdk(validation)
    result = {}
    
    android_home = ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT']
    result[:android_home] = android_home
    result[:available] = !android_home.nil? && Dir.exist?(android_home)
    
    if result[:available]
      # Check for essential SDK components
      sdk_manager_path = File.join(android_home, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
      adb_path = File.join(android_home, 'platform-tools', 'adb')
      
      result[:sdk_manager_exists] = File.exist?(sdk_manager_path)
      result[:adb_exists] = File.exist?(adb_path)
      
      unless result[:sdk_manager_exists]
        validation[:issues] << {
          type: 'android_sdk',
          message: "SDK Manager not found in Android SDK",
          severity: 'medium'
        }
      end
      
      unless result[:adb_exists]
        validation[:issues] << {
          type: 'android_sdk',
          message: "ADB not found in Android SDK",
          severity: 'medium'
        }
      end
    else
      validation[:issues] << {
        type: 'android_sdk',
        message: "Android SDK not found. Set ANDROID_HOME environment variable.",
        severity: 'high'
      }
    end
    
    result
  end
  
  def self.check_java_installation(validation)
    result = {}
    
    begin
      output, status = Open3.capture2e('java -version')
      result[:available] = status.success?
      result[:version_output] = output.strip
      
      unless status.success?
        validation[:issues] << {
          type: 'java',
          message: "Java not found or not working properly",
          severity: 'high'
        }
      end
    rescue => e
      result[:available] = false
      result[:error] = e.message
      validation[:issues] << {
        type: 'java',
        message: "Java not found: #{e.message}",
        severity: 'high'
      }
    end
    
    result
  end
  
  def self.check_gradle_installation(validation)
    result = {}
    
    # Check for Gradle wrapper
    gradle_wrapper = File.join(Dir.pwd, '..', 'gradlew')
    result[:gradle_wrapper_exists] = File.exist?(gradle_wrapper)
    
    if result[:gradle_wrapper_exists]
      begin
        Dir.chdir('..') do
          output, status = Open3.capture2e('./gradlew --version')
          result[:wrapper_working] = status.success?
          result[:version_output] = output.strip if status.success?
        end
      rescue => e
        result[:wrapper_working] = false
        result[:error] = e.message
      end
    else
      validation[:issues] << {
        type: 'gradle',
        message: "Gradle wrapper not found",
        severity: 'medium'
      }
    end
    
    result
  end
  
  def self.check_git_installation(validation)
    result = {}
    
    begin
      output, status = Open3.capture2e('git --version')
      result[:available] = status.success?
      result[:version_output] = output.strip if status.success?
      
      unless status.success?
        validation[:recommendations] << "Install Git for version control features"
      end
    rescue => e
      result[:available] = false
      result[:error] = e.message
    end
    
    result
  end
  
  def self.check_ruby_installation(validation)
    result = {
      version: RUBY_VERSION,
      platform: RUBY_PLATFORM,
      available: true
    }
    
    # Check if Ruby version is compatible
    ruby_version = Gem::Version.new(RUBY_VERSION)
    min_version = Gem::Version.new('2.6.0')
    
    if ruby_version < min_version
      validation[:issues] << {
        type: 'ruby',
        message: "Ruby version #{RUBY_VERSION} is below recommended minimum #{min_version}",
        severity: 'medium'
      }
    end
    
    result
  end
  
  def self.check_fastlane_installation(validation)
    result = {
      version: Fastlane::VERSION,
      available: true
    }
    
    # Check if Fastlane is up to date (this is just informational)
    result[:current_version] = Fastlane::VERSION
    
    result
  end
  
  def self.analyze_log_content(log_file, analysis)
    content = File.read(log_file)
    lines = content.lines
    
    # Common error patterns
    error_patterns = {
      'gradle_error' => /FAILURE: Build failed with an exception/i,
      'flutter_error' => /Error: .+/,
      'signing_error' => /(keystore|certificate|signing).*(error|failed)/i,
      'network_error' => /(connection|network|timeout).*(error|failed)/i,
      'permission_error' => /(permission|access).*(denied|error)/i,
      'dependency_error' => /(dependency|package).*(not found|error)/i
    }
    
    # Warning patterns
    warning_patterns = {
      'deprecation_warning' => /deprecated/i,
      'version_warning' => /version.*(mismatch|conflict)/i,
      'configuration_warning' => /configuration.*(warning|issue)/i
    }
    
    # Analyze patterns
    error_patterns.each do |pattern_name, pattern|
      matches = lines.select { |line| line.match?(pattern) }
      if matches.any?
        analysis[:patterns][pattern_name] = matches.count
        analysis[:errors] += matches.map { |match| match.strip }
      end
    end
    
    warning_patterns.each do |pattern_name, pattern|
      matches = lines.select { |line| line.match?(pattern) }
      if matches.any?
        analysis[:patterns][pattern_name] = matches.count
        analysis[:warnings] += matches.map { |match| match.strip }
      end
    end
    
    # Generate suggestions based on patterns
    generate_failure_suggestions(analysis)
  end
  
  def self.generate_failure_suggestions(analysis)
    if analysis[:patterns]['gradle_error']
      analysis[:suggestions] << "Gradle build failed. Try running './gradlew clean' and retry."
    end
    
    if analysis[:patterns]['flutter_error']
      analysis[:suggestions] << "Flutter errors detected. Run 'flutter clean' and 'flutter pub get'."
    end
    
    if analysis[:patterns]['signing_error']
      analysis[:suggestions] << "Signing errors detected. Check keystore file and environment variables."
    end
    
    if analysis[:patterns]['network_error']
      analysis[:suggestions] << "Network errors detected. Check internet connectivity and API URLs."
    end
    
    if analysis[:patterns]['permission_error']
      analysis[:suggestions] << "Permission errors detected. Check file and directory permissions."
    end
    
    if analysis[:patterns]['dependency_error']
      analysis[:suggestions] << "Dependency errors detected. Update dependencies and check versions."
    end
  end
  
  # Additional helper methods for report generation and display...
  
  def self.generate_diagnosis_report(diagnosis)
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'diagnosis_reports')
    FileUtils.mkdir_p(report_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    report_file = File.join(report_dir, "diagnosis_#{diagnosis[:environment]}_#{timestamp}.json")
    
    File.write(report_file, JSON.pretty_generate(diagnosis))
    UI.message("📄 Diagnosis report saved to #{report_file}")
  end
  
  def self.display_diagnosis_summary(diagnosis)
    UI.message("")
    UI.message("DIAGNOSIS SUMMARY")
    UI.message("=" * 50)
    
    if diagnosis[:issues].any?
      UI.error("❌ Found #{diagnosis[:issues].count} issues:")
      diagnosis[:issues].each_with_index do |issue, index|
        severity_icon = case issue[:severity]
                       when 'high' then '🔴'
                       when 'medium' then '🟡'
                       when 'low' then '🟢'
                       else '⚪'
                       end
        UI.error("   #{index + 1}. #{severity_icon} #{issue[:message]}")
      end
    else
      UI.success("✅ No issues found")
    end
    
    if diagnosis[:recommendations].any?
      UI.message("")
      UI.important("💡 Recommendations:")
      diagnosis[:recommendations].each_with_index do |rec, index|
        UI.important("   #{index + 1}. #{rec}")
      end
    end
  end
  
  def self.generate_validation_report(validation)
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'validation_reports')
    FileUtils.mkdir_p(report_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    report_file = File.join(report_dir, "build_env_validation_#{timestamp}.json")
    
    File.write(report_file, JSON.pretty_generate(validation))
    UI.message("📄 Validation report saved to #{report_file}")
  end
  
  def self.display_validation_summary(validation)
    UI.message("")
    UI.message("BUILD ENVIRONMENT VALIDATION")
    UI.message("=" * 50)
    
    validation[:tools].each do |tool, info|
      if info[:available]
        UI.success("✅ #{tool.to_s.capitalize}: Available")
      else
        UI.error("❌ #{tool.to_s.capitalize}: Not available")
      end
    end
    
    if validation[:issues].any?
      UI.message("")
      UI.error("Issues found:")
      validation[:issues].each_with_index do |issue, index|
        UI.error("   #{index + 1}. #{issue[:message]}")
      end
    end
  end
  
  def self.generate_analysis_report(analysis)
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'analysis_reports')
    FileUtils.mkdir_p(report_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    report_file = File.join(report_dir, "build_failure_analysis_#{timestamp}.json")
    
    File.write(report_file, JSON.pretty_generate(analysis))
    UI.message("📄 Analysis report saved to #{report_file}")
  end
  
  def self.display_analysis_summary(analysis)
    UI.message("")
    UI.message("BUILD FAILURE ANALYSIS")
    UI.message("=" * 50)
    UI.message("Log file: #{File.basename(analysis[:log_file])}")
    UI.message("Errors found: #{analysis[:errors].count}")
    UI.message("Warnings found: #{analysis[:warnings].count}")
    
    if analysis[:suggestions].any?
      UI.message("")
      UI.important("💡 Suggestions:")
      analysis[:suggestions].each_with_index do |suggestion, index|
        UI.important("   #{index + 1}. #{suggestion}")
      end
    end
  end
  
  # Additional methods for integrity checking, signing tests, etc.
  # ... (continuing with the same pattern)
end