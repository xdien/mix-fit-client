require 'yaml'
require 'json'
require_relative 'artifact_manager'

class ConfigLoader
  def self.load_environment_config(environment)
    config_path = File.join(Dir.pwd, '..', '..', 'config', 'environments', "#{environment}.yaml")
    
    unless File.exist?(config_path)
      raise ConfigValidationError.new("Configuration file not found: #{config_path}")
    end
    
    begin
      config = YAML.load_file(config_path)
      validate_config(config, environment)
      config
    rescue YAML::SyntaxError => e
      raise ConfigValidationError.new("Invalid YAML syntax in configuration file: #{e.message}")
    rescue => e
      if e.is_a?(ConfigValidationError)
        raise e
      else
        raise ConfigValidationError.new("Failed to load configuration for #{environment}: #{e.message}")
      end
    end
  end
  
  def self.validate_config(config, environment)
    validation_errors = []
    
    # Check required top-level keys
    required_keys = %w[environment app network build signing]
    required_keys.each do |key|
      unless config.key?(key)
        validation_errors << {
          type: 'missing_section',
          section: key,
          message: "Missing required configuration section '#{key}'"
        }
      end
    end
    
    # Validate app configuration
    if config['app']
      app_config = config['app']
      %w[name bundle_id].each do |key|
        unless app_config.key?(key)
          validation_errors << {
            type: 'missing_field',
            section: 'app',
            field: key,
            message: "Missing required app configuration field '#{key}'"
          }
        end
      end
      
      # Validate bundle ID format
      if app_config['bundle_id']
        bundle_id = app_config['bundle_id']
        unless bundle_id.match?(/^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$/)
          validation_errors << {
            type: 'invalid_format',
            section: 'app',
            field: 'bundle_id',
            value: bundle_id,
            message: "Invalid bundle ID format: #{bundle_id}"
          }
        end
      end
      
      # Validate version format if present
      if app_config['version_name']
        version = app_config['version_name']
        unless version.match?(/^\d+\.\d+\.\d+(-\w+)?$/)
          validation_errors << {
            type: 'invalid_format',
            section: 'app',
            field: 'version_name',
            value: version,
            message: "Invalid version format: #{version}. Expected semantic versioning (e.g., 1.0.0)"
          }
        end
      end
    end
    
    # Validate network configuration
    if config['network']
      network_config = config['network']
      unless network_config.key?('api_base_url')
        validation_errors << {
          type: 'missing_field',
          section: 'network',
          field: 'api_base_url',
          message: "Missing required network configuration field 'api_base_url'"
        }
      end
      
      # Validate URL format
      if network_config['api_base_url']
        url = network_config['api_base_url']
        begin
          uri = URI.parse(url)
          unless uri.scheme && uri.host
            validation_errors << {
              type: 'invalid_url',
              section: 'network',
              field: 'api_base_url',
              value: url,
              message: "Invalid URL format for api_base_url: #{url}"
            }
          end
        rescue URI::InvalidURIError
          validation_errors << {
            type: 'invalid_url',
            section: 'network',
            field: 'api_base_url',
            value: url,
            message: "Malformed URL for api_base_url: #{url}"
          }
        end
      end
    end
    
    # Validate signing configuration
    if config['signing']
      signing_config = config['signing']
      %w[store_file store_password_env key_alias key_password_env].each do |key|
        unless signing_config.key?(key)
          validation_errors << {
            type: 'missing_field',
            section: 'signing',
            field: key,
            message: "Missing required signing configuration field '#{key}'"
          }
        end
      end
      
      # Check if keystore file exists
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
    
    # Raise error if validation failed
    if validation_errors.any?
      error_message = "Configuration validation failed for #{environment} environment with #{validation_errors.count} errors"
      raise ConfigValidationError.new(error_message, validation_errors)
    end
    
    FastlaneCore::UI.success("✅ Configuration validation passed for #{environment} environment")
  end
  
  def self.setup_flutter_environment(config)
    # Set environment variables for Flutter build
    ENV['API_BASE_URL'] = config['network']['api_base_url']
    ENV['WEBSOCKET_URL'] = config['network']['websocket_url'] if config['network']['websocket_url']
    ENV['APP_NAME'] = config['app']['name']
    ENV['BUNDLE_ID'] = config['app']['bundle_id']
    ENV['ENVIRONMENT'] = config['environment']['name']
    
    # Set build configuration
    build_config = config['build']
    ENV['BUILD_FLAVOR'] = build_config['flavor'] if build_config['flavor']
    ENV['BUILD_TYPE'] = build_config['build_type'] if build_config['build_type']
    
    FastlaneCore::UI.message("🔧 Environment variables set for #{config['environment']['name']} environment")
  end
  
  def self.get_build_command(config, build_type = nil)
    build_config = config['build']
    actual_build_type = build_type || build_config['build_type'] || 'release'
    flavor = build_config['flavor']
    
    command_parts = ['flutter', 'build', 'apk']
    
    # Add build type
    if actual_build_type == 'debug'
      command_parts << '--debug'
    else
      command_parts << '--release'
    end
    
    # Add flavor if specified (skip for development to avoid flavor issues)
    if flavor && flavor != 'production' && flavor != 'development'
      command_parts << "--flavor=#{flavor}"
    end
    
    # Add build name and number
    if config['app']['version_name']
      command_parts << "--build-name=#{config['app']['version_name']}"
    end
    
    if config['app']['version_code']
      command_parts << "--build-number=#{config['app']['version_code']}"
    end
    
    # Add obfuscation settings
    if build_config['obfuscate']
      command_parts << '--obfuscate'
      command_parts << '--split-debug-info=build/debug-info'
    end
    
    # Add resource shrinking
    if build_config['shrink_resources']
      command_parts << '--shrink'
    end
    
    command_parts.join(' ')
  end
  
  def self.get_output_filename(config, build_type = nil)
    app_name = config['app']['name'].downcase.gsub(/\s+/, '-')
    environment = config['environment']['name']
    actual_build_type = build_type || config['build']['build_type'] || 'release'
    version = config['app']['version_name'] || '1.0.0'
    
    "#{app_name}-#{environment}-#{actual_build_type}-#{version}.apk"
  end
  
  def self.create_build_info(config, build_type = nil)
    build_info = {
      environment: config['environment']['name'],
      app_name: config['app']['name'],
      bundle_id: config['app']['bundle_id'],
      version_name: config['app']['version_name'],
      version_code: config['app']['version_code'],
      build_type: build_type || config['build']['build_type'],
      build_time: Time.now.iso8601,
      api_base_url: config['network']['api_base_url'],
      websocket_url: config['network']['websocket_url']
    }
    
    build_info_path = File.join(Dir.pwd, '..', '..', 'build', 'build-info.json')
    FileUtils.mkdir_p(File.dirname(build_info_path))
    
    File.write(build_info_path, JSON.pretty_generate(build_info))
    FastlaneCore::UI.success("📋 Build info created at #{build_info_path}")
    
    build_info
  end
  
  def self.organize_build_artifacts(config, build_type = nil)
    artifact_manager = ArtifactManager.new(config, build_type)
    artifact_manager.organize_build_artifacts
  end
end