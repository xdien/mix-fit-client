# Error Handler for Fastlane Environment Configuration
# Provides comprehensive error handling, logging, and recovery mechanisms

require 'logger'
require 'json'
require 'fileutils'

class ErrorHandler
  attr_reader :logger, :error_log_path, :debug_mode
  
  def initialize(environment = 'development', debug_mode = false)
    @environment = environment
    @debug_mode = debug_mode || ENV['FASTLANE_DEBUG'] == 'true'
    @error_log_path = setup_logging
    @recovery_strategies = setup_recovery_strategies
  end
  
  # Main error handling method
  def handle_error(error, context = {})
    error_info = {
      timestamp: Time.now.iso8601,
      environment: @environment,
      error_class: error.class.name,
      error_message: error.message,
      error_backtrace: error.backtrace,
      context: context,
      recovery_attempted: false,
      recovery_successful: false
    }
    
    # Log the error
    log_error(error_info)
    
    # Attempt recovery if strategy exists
    recovery_strategy = find_recovery_strategy(error, context)
    if recovery_strategy
      error_info[:recovery_attempted] = true
      begin
        recovery_result = recovery_strategy.call(error, context)
        error_info[:recovery_successful] = recovery_result[:success]
        error_info[:recovery_details] = recovery_result[:details]
        
        if recovery_result[:success]
          FastlaneCore::UI.important("🔄 Error recovered: #{recovery_result[:message]}")
          log_recovery_success(error_info)
          return recovery_result
        else
          FastlaneCore::UI.error("❌ Recovery failed: #{recovery_result[:message]}")
          log_recovery_failure(error_info)
        end
      rescue => recovery_error
        error_info[:recovery_error] = {
          class: recovery_error.class.name,
          message: recovery_error.message,
          backtrace: recovery_error.backtrace
        }
        FastlaneCore::UI.error("💥 Recovery attempt failed: #{recovery_error.message}")
        log_recovery_failure(error_info)
      end
    end
    
    # Generate error report
    generate_error_report(error_info)
    
    # Re-raise the original error if no recovery
    raise error
  end
  
  # Wrap a block with error handling
  def with_error_handling(context = {})
    begin
      yield
    rescue => error
      handle_error(error, context)
    end
  end
  
  # Log informational messages with context
  def log_info(message, context = {})
    log_entry = {
      level: 'INFO',
      timestamp: Time.now.iso8601,
      environment: @environment,
      message: message,
      context: context
    }
    
    @logger.info(JSON.generate(log_entry))
    FastlaneCore::UI.message("ℹ️  #{message}")
  end
  
  # Log warning messages
  def log_warning(message, context = {})
    log_entry = {
      level: 'WARNING',
      timestamp: Time.now.iso8601,
      environment: @environment,
      message: message,
      context: context
    }
    
    @logger.warn(JSON.generate(log_entry))
    FastlaneCore::UI.important("⚠️  #{message}")
  end
  
  # Log debug messages (only in debug mode)
  def log_debug(message, context = {})
    return unless @debug_mode
    
    log_entry = {
      level: 'DEBUG',
      timestamp: Time.now.iso8601,
      environment: @environment,
      message: message,
      context: context
    }
    
    @logger.debug(JSON.generate(log_entry))
    FastlaneCore::UI.verbose("🐛 #{message}")
  end
  
  # Validate configuration with detailed error reporting
  def validate_configuration(config, config_path)
    validation_errors = []
    
    begin
      # Basic structure validation
      required_sections = %w[environment app network build signing]
      required_sections.each do |section|
        unless config.key?(section)
          validation_errors << {
            type: 'missing_section',
            section: section,
            message: "Missing required configuration section '#{section}'"
          }
        end
      end
      
      # Environment section validation
      if config['environment']
        env_config = config['environment']
        unless env_config['name']
          validation_errors << {
            type: 'missing_field',
            section: 'environment',
            field: 'name',
            message: "Environment name is required"
          }
        end
        
        valid_environments = %w[development staging production]
        if env_config['name'] && !valid_environments.include?(env_config['name'])
          validation_errors << {
            type: 'invalid_value',
            section: 'environment',
            field: 'name',
            value: env_config['name'],
            valid_values: valid_environments,
            message: "Invalid environment name. Must be one of: #{valid_environments.join(', ')}"
          }
        end
      end
      
      # App section validation
      if config['app']
        app_config = config['app']
        
        # Bundle ID validation
        if app_config['bundle_id']
          bundle_id = app_config['bundle_id']
          unless bundle_id.match?(/^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$/)
            validation_errors << {
              type: 'invalid_format',
              section: 'app',
              field: 'bundle_id',
              value: bundle_id,
              pattern: '^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$',
              message: "Invalid bundle ID format. Must follow reverse domain notation (e.g., com.example.app)"
            }
          end
        else
          validation_errors << {
            type: 'missing_field',
            section: 'app',
            field: 'bundle_id',
            message: "Bundle ID is required"
          }
        end
        
        # Version validation
        if app_config['version_name']
          version = app_config['version_name']
          unless version.match?(/^\d+\.\d+\.\d+(-\w+)?$/)
            validation_errors << {
              type: 'invalid_format',
              section: 'app',
              field: 'version_name',
              value: version,
              pattern: '^\d+\.\d+\.\d+(-\w+)?$',
              message: "Invalid version format. Must follow semantic versioning (e.g., 1.0.0 or 1.0.0-beta)"
            }
          end
        end
        
        if app_config['version_code'] && !app_config['version_code'].is_a?(Integer)
          validation_errors << {
            type: 'invalid_type',
            section: 'app',
            field: 'version_code',
            value: app_config['version_code'],
            expected_type: 'Integer',
            message: "Version code must be an integer"
          }
        end
      end
      
      # Network section validation
      if config['network']
        network_config = config['network']
        
        # URL validation
        %w[api_base_url websocket_url].each do |url_field|
          if network_config[url_field]
            url = network_config[url_field]
            begin
              uri = URI.parse(url)
              unless uri.scheme && uri.host
                validation_errors << {
                  type: 'invalid_url',
                  section: 'network',
                  field: url_field,
                  value: url,
                  message: "Invalid URL format for #{url_field}"
                }
              end
            rescue URI::InvalidURIError
              validation_errors << {
                type: 'invalid_url',
                section: 'network',
                field: url_field,
                value: url,
                message: "Malformed URL for #{url_field}"
              }
            end
          end
        end
        
        # Timeout validation
        if network_config['timeout']
          timeout = network_config['timeout']
          unless timeout.is_a?(Integer) && timeout > 0
            validation_errors << {
              type: 'invalid_value',
              section: 'network',
              field: 'timeout',
              value: timeout,
              message: "Timeout must be a positive integer (milliseconds)"
            }
          end
        end
      end
      
      # Signing section validation
      if config['signing']
        signing_config = config['signing']
        
        required_signing_fields = %w[store_file store_password_env key_alias key_password_env]
        required_signing_fields.each do |field|
          unless signing_config[field]
            validation_errors << {
              type: 'missing_field',
              section: 'signing',
              field: field,
              message: "Signing field '#{field}' is required"
            }
          end
        end
        
        # Validate keystore file exists
        if signing_config['store_file']
          keystore_path = File.join(Dir.pwd, '..', 'keystores', signing_config['store_file'])
          unless File.exist?(keystore_path)
            validation_errors << {
              type: 'file_not_found',
              section: 'signing',
              field: 'store_file',
              path: keystore_path,
              message: "Keystore file not found: #{keystore_path}"
            }
          end
        end
      end
      
      # Report validation results
      if validation_errors.any?
        error_report = {
          config_path: config_path,
          environment: @environment,
          validation_errors: validation_errors,
          error_count: validation_errors.count
        }
        
        log_validation_errors(error_report)
        generate_validation_report(error_report)
        
        raise ConfigValidationError.new("Configuration validation failed with #{validation_errors.count} errors", validation_errors)
      else
        log_info("Configuration validation passed", { config_path: config_path })
      end
      
    rescue => error
      context = {
        config_path: config_path,
        validation_errors: validation_errors
      }
      handle_error(error, context)
    end
  end
  
  # Generate comprehensive error report
  def generate_error_report(error_info)
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'error_reports')
    FileUtils.mkdir_p(report_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    report_file = File.join(report_dir, "error_report_#{@environment}_#{timestamp}.json")
    
    # Add system information
    error_info[:system_info] = {
      ruby_version: RUBY_VERSION,
      fastlane_version: Fastlane::VERSION,
      platform: RUBY_PLATFORM,
      working_directory: Dir.pwd,
      environment_variables: get_relevant_env_vars
    }
    
    File.write(report_file, JSON.pretty_generate(error_info))
    
    FastlaneCore::UI.important("📄 Error report generated: #{report_file}")
    
    # Also create a human-readable summary
    summary_file = File.join(report_dir, "error_summary_#{@environment}_#{timestamp}.txt")
    generate_error_summary(error_info, summary_file)
  end
  
  # Generate debugging information
  def generate_debug_info(context = {})
    debug_info = {
      timestamp: Time.now.iso8601,
      environment: @environment,
      context: context,
      system_info: {
        ruby_version: RUBY_VERSION,
        fastlane_version: Fastlane::VERSION,
        platform: RUBY_PLATFORM,
        working_directory: Dir.pwd
      },
      environment_variables: get_relevant_env_vars,
      file_system: {
        config_files: check_config_files,
        keystore_files: check_keystore_files,
        build_directories: check_build_directories
      }
    }
    
    debug_dir = File.join(Dir.pwd, '..', '..', 'build', 'debug_info')
    FileUtils.mkdir_p(debug_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    debug_file = File.join(debug_dir, "debug_info_#{@environment}_#{timestamp}.json")
    
    File.write(debug_file, JSON.pretty_generate(debug_info))
    
    FastlaneCore::UI.message("🐛 Debug info generated: #{debug_file}")
    debug_info
  end
  
  private
  
  def setup_logging
    log_dir = File.join(Dir.pwd, '..', '..', 'build', 'logs')
    FileUtils.mkdir_p(log_dir)
    
    log_file = File.join(log_dir, "fastlane_#{@environment}.log")
    
    @logger = Logger.new(log_file, 'daily')
    @logger.level = @debug_mode ? Logger::DEBUG : Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.iso8601} [#{severity}] #{msg}\n"
    end
    
    log_file
  end
  
  def setup_recovery_strategies
    {
      'ConfigValidationError' => method(:recover_config_validation),
      'SigningError' => method(:recover_signing_error),
      'BuildError' => method(:recover_build_error),
      'NetworkError' => method(:recover_network_error),
      'FileNotFoundError' => method(:recover_file_not_found),
      'PermissionError' => method(:recover_permission_error)
    }
  end
  
  def find_recovery_strategy(error, context)
    error_class = error.class.name
    
    # Direct match
    return @recovery_strategies[error_class] if @recovery_strategies[error_class]
    
    # Pattern matching
    case error.message
    when /configuration/i
      @recovery_strategies['ConfigValidationError']
    when /signing|keystore|certificate/i
      @recovery_strategies['SigningError']
    when /build|flutter/i
      @recovery_strategies['BuildError']
    when /network|connection|timeout/i
      @recovery_strategies['NetworkError']
    when /no such file|not found/i
      @recovery_strategies['FileNotFoundError']
    when /permission|access denied/i
      @recovery_strategies['PermissionError']
    else
      nil
    end
  end
  
  # Recovery strategies
  
  def recover_config_validation(error, context)
    {
      success: false,
      message: "Configuration validation cannot be automatically recovered. Please fix the configuration errors.",
      details: {
        suggestion: "Check the error report for detailed validation errors and fix the configuration file."
      }
    }
  end
  
  def recover_signing_error(error, context)
    # Try to generate debug keystore for development environment
    if @environment == 'development' && error.message.include?('keystore')
      begin
        debug_keystore_path = File.join(Dir.pwd, '..', 'keystores', 'debug.keystore')
        
        unless File.exist?(debug_keystore_path)
          FileUtils.mkdir_p(File.dirname(debug_keystore_path))
          
          # Generate debug keystore
          keytool_cmd = [
            'keytool', '-genkey', '-v',
            '-keystore', debug_keystore_path,
            '-alias', 'androiddebugkey',
            '-keyalg', 'RSA',
            '-keysize', '2048',
            '-validity', '10000',
            '-storepass', 'android',
            '-keypass', 'android',
            '-dname', 'CN=Android Debug,O=Android,C=US'
          ].join(' ')
          
          system(keytool_cmd)
          
          if File.exist?(debug_keystore_path)
            return {
              success: true,
              message: "Generated debug keystore for development environment",
              details: {
                keystore_path: debug_keystore_path,
                alias: 'androiddebugkey',
                passwords: 'android'
              }
            }
          end
        end
      rescue => recovery_error
        return {
          success: false,
          message: "Failed to generate debug keystore: #{recovery_error.message}",
          details: { error: recovery_error.message }
        }
      end
    end
    
    {
      success: false,
      message: "Signing error cannot be automatically recovered",
      details: {
        suggestion: "Check keystore file exists and environment variables are set correctly"
      }
    }
  end
  
  def recover_build_error(error, context)
    # Try to clean and retry for common build issues
    if error.message.include?('flutter') || error.message.include?('gradle')
      begin
        FastlaneCore::UI.message("🧹 Attempting to clean build cache...")
        
        # Clean Flutter
        Dir.chdir(File.join(Dir.pwd, '..', '..')) do
          system('flutter clean')
          system('flutter pub get')
        end
        
        # Clean Android
        Dir.chdir('..') do
          system('./gradlew clean')
        end
        
        return {
          success: true,
          message: "Cleaned build cache, retry the build",
          details: {
            actions_taken: ['flutter clean', 'flutter pub get', 'gradlew clean']
          }
        }
      rescue => recovery_error
        return {
          success: false,
          message: "Failed to clean build cache: #{recovery_error.message}",
          details: { error: recovery_error.message }
        }
      end
    end
    
    {
      success: false,
      message: "Build error cannot be automatically recovered",
      details: {
        suggestion: "Check build logs for specific error details"
      }
    }
  end
  
  def recover_network_error(error, context)
    {
      success: false,
      message: "Network error cannot be automatically recovered",
      details: {
        suggestion: "Check network connectivity and URL configuration"
      }
    }
  end
  
  def recover_file_not_found(error, context)
    # Try to create missing directories
    if error.message.include?('directory') || error.message.include?('folder')
      begin
        # Extract path from error message or context
        missing_path = context[:path] || extract_path_from_error(error.message)
        
        if missing_path && !File.exist?(missing_path)
          FileUtils.mkdir_p(missing_path)
          
          return {
            success: true,
            message: "Created missing directory: #{missing_path}",
            details: { created_path: missing_path }
          }
        end
      rescue => recovery_error
        return {
          success: false,
          message: "Failed to create missing directory: #{recovery_error.message}",
          details: { error: recovery_error.message }
        }
      end
    end
    
    {
      success: false,
      message: "File not found error cannot be automatically recovered",
      details: {
        suggestion: "Check file paths and ensure required files exist"
      }
    }
  end
  
  def recover_permission_error(error, context)
    {
      success: false,
      message: "Permission error cannot be automatically recovered",
      details: {
        suggestion: "Check file permissions and user access rights"
      }
    }
  end
  
  # Logging helpers
  
  def log_error(error_info)
    @logger.error(JSON.generate(error_info))
    
    FastlaneCore::UI.error("💥 Error in #{error_info[:context][:operation] || 'unknown operation'}")
    FastlaneCore::UI.error("   Class: #{error_info[:error_class]}")
    FastlaneCore::UI.error("   Message: #{error_info[:error_message]}")
    
    if @debug_mode && error_info[:error_backtrace]
      FastlaneCore::UI.verbose("   Backtrace:")
      error_info[:error_backtrace].first(10).each do |line|
        FastlaneCore::UI.verbose("     #{line}")
      end
    end
  end
  
  def log_recovery_success(error_info)
    @logger.info("Recovery successful: #{JSON.generate(error_info[:recovery_details])}")
  end
  
  def log_recovery_failure(error_info)
    @logger.error("Recovery failed: #{JSON.generate(error_info[:recovery_details])}")
  end
  
  def log_validation_errors(error_report)
    @logger.error("Configuration validation failed: #{JSON.generate(error_report)}")
    
    FastlaneCore::UI.error("❌ Configuration validation failed with #{error_report[:error_count]} errors:")
    error_report[:validation_errors].each_with_index do |error, index|
      FastlaneCore::UI.error("   #{index + 1}. #{error[:message]}")
      if error[:section] && error[:field]
        FastlaneCore::UI.error("      Section: #{error[:section]}, Field: #{error[:field]}")
      end
    end
  end
  
  def generate_validation_report(error_report)
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'validation_reports')
    FileUtils.mkdir_p(report_dir)
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    report_file = File.join(report_dir, "validation_report_#{@environment}_#{timestamp}.json")
    
    File.write(report_file, JSON.pretty_generate(error_report))
    FastlaneCore::UI.important("📄 Validation report generated: #{report_file}")
  end
  
  def generate_error_summary(error_info, summary_file)
    summary = []
    summary << "ERROR SUMMARY"
    summary << "=" * 50
    summary << "Timestamp: #{error_info[:timestamp]}"
    summary << "Environment: #{error_info[:environment]}"
    summary << "Error Class: #{error_info[:error_class]}"
    summary << "Error Message: #{error_info[:error_message]}"
    summary << ""
    
    if error_info[:context].any?
      summary << "CONTEXT:"
      error_info[:context].each do |key, value|
        summary << "  #{key}: #{value}"
      end
      summary << ""
    end
    
    if error_info[:recovery_attempted]
      summary << "RECOVERY ATTEMPTED: #{error_info[:recovery_successful] ? 'SUCCESS' : 'FAILED'}"
      if error_info[:recovery_details]
        summary << "Recovery Details: #{error_info[:recovery_details][:message]}"
      end
      summary << ""
    end
    
    summary << "TROUBLESHOOTING SUGGESTIONS:"
    summary << get_troubleshooting_suggestions(error_info)
    
    File.write(summary_file, summary.join("\n"))
    FastlaneCore::UI.important("📋 Error summary generated: #{summary_file}")
  end
  
  def get_troubleshooting_suggestions(error_info)
    suggestions = []
    
    case error_info[:error_class]
    when 'ConfigValidationError'
      suggestions << "1. Check configuration file syntax and required fields"
      suggestions << "2. Validate bundle ID format and environment values"
      suggestions << "3. Ensure all required sections are present"
    when /Signing/
      suggestions << "1. Verify keystore file exists and is accessible"
      suggestions << "2. Check environment variables for passwords"
      suggestions << "3. Validate certificate expiration and alias"
    when /Build/
      suggestions << "1. Run 'flutter clean' and 'flutter pub get'"
      suggestions << "2. Check Flutter and Android SDK versions"
      suggestions << "3. Verify build configuration and dependencies"
    when /Network/
      suggestions << "1. Check network connectivity"
      suggestions << "2. Validate API URLs and endpoints"
      suggestions << "3. Verify firewall and proxy settings"
    else
      suggestions << "1. Check the error message for specific details"
      suggestions << "2. Review the full error log for more context"
      suggestions << "3. Consult the documentation for troubleshooting"
    end
    
    suggestions.join("\n")
  end
  
  def get_relevant_env_vars
    env_vars = {}
    
    # Fastlane-related environment variables
    %w[
      FASTLANE_DEBUG FASTLANE_VERBOSE FASTLANE_SKIP_UPDATE_CHECK
      CI GITHUB_ACTIONS JENKINS_URL
      API_BASE_URL WEBSOCKET_URL APP_NAME BUNDLE_ID ENVIRONMENT
      BUILD_FLAVOR BUILD_TYPE
    ].each do |var|
      env_vars[var] = ENV[var] if ENV[var]
    end
    
    # Signing-related (without exposing passwords)
    %w[
      STORE_PASSWORD_DEV STORE_PASSWORD_STAGING STORE_PASSWORD_PROD
      KEY_PASSWORD_DEV KEY_PASSWORD_STAGING KEY_PASSWORD_PROD
    ].each do |var|
      env_vars[var] = ENV[var] ? '[SET]' : '[NOT SET]'
    end
    
    env_vars
  end
  
  def check_config_files
    config_dir = File.join(Dir.pwd, '..', '..', 'config', 'environments')
    files = {}
    
    %w[development.yaml staging.yaml production.yaml].each do |file|
      path = File.join(config_dir, file)
      files[file] = {
        exists: File.exist?(path),
        size: File.exist?(path) ? File.size(path) : 0,
        modified: File.exist?(path) ? File.mtime(path).iso8601 : nil
      }
    end
    
    files
  end
  
  def check_keystore_files
    keystore_dir = File.join(Dir.pwd, '..', 'keystores')
    files = {}
    
    if Dir.exist?(keystore_dir)
      Dir.glob(File.join(keystore_dir, '*.keystore')).each do |path|
        filename = File.basename(path)
        files[filename] = {
          exists: true,
          size: File.size(path),
          modified: File.mtime(path).iso8601
        }
      end
    end
    
    files
  end
  
  def check_build_directories
    build_dir = File.join(Dir.pwd, '..', '..', 'build')
    directories = {}
    
    if Dir.exist?(build_dir)
      %w[android logs error_reports debug_info validation_reports].each do |dir|
        path = File.join(build_dir, dir)
        directories[dir] = {
          exists: Dir.exist?(path),
          file_count: Dir.exist?(path) ? Dir.glob(File.join(path, '**', '*')).count : 0
        }
      end
    end
    
    directories
  end
  
  def extract_path_from_error(error_message)
    # Try to extract file/directory path from error message
    path_match = error_message.match(/(?:file|directory|path).*?['"`]([^'"`]+)['"`]/)
    path_match ? path_match[1] : nil
  end
end

# Custom error classes
class ConfigValidationError < StandardError
  attr_reader :validation_errors
  
  def initialize(message, validation_errors = [])
    super(message)
    @validation_errors = validation_errors
  end
end

class SigningError < StandardError; end
class BuildError < StandardError; end
class NetworkError < StandardError; end