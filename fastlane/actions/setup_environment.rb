require 'json'

module Fastlane
  module Actions
    class SetupEnvironmentAction < Action
      def self.run(params)
        environment = params[:environment] || 'development'
        
        UI.message("Setting up environment: #{environment}")
        
        # Load configuration file
        config_path = File.join(FastlaneCore::FastlaneFolder.path, 'config', "#{environment}.json")
        
        unless File.exist?(config_path)
          UI.user_error!("Configuration file not found: #{config_path}")
        end
        
        begin
          config_content = File.read(config_path)
          config = JSON.parse(config_content)
        rescue JSON::ParserError => e
          UI.user_error!("Invalid JSON in configuration file #{config_path}: #{e.message}")
        rescue => e
          UI.user_error!("Error reading configuration file #{config_path}: #{e.message}")
        end
        
        # Validate required configuration parameters
        validate_configuration(config, environment)
        
        # Set environment variables and lane context
        setup_lane_context(config)
        
        # Display configuration summary
        display_configuration_summary(config)
        
        UI.success("Environment '#{environment}' configured successfully")
        
        return config
      end
      
      private
      
      def self.validate_configuration(config, environment)
        UI.message("Validating configuration for environment: #{environment}")
        
        # Validate required top-level keys
        required_keys = ['environment', 'android', 'windows', 'linux', 'flutter', 'distribution']
        missing_keys = required_keys.select { |key| !config.key?(key) }
        
        unless missing_keys.empty?
          UI.user_error!("Missing required configuration keys: #{missing_keys.join(', ')}")
        end
        
        # Validate Android configuration
        validate_android_config(config['android'])
        
        # Validate Windows configuration
        validate_windows_config(config['windows'])
        
        # Validate Linux configuration
        validate_linux_config(config['linux'])
        
        # Validate Flutter configuration
        validate_flutter_config(config['flutter'])
        
        # Validate distribution configuration
        validate_distribution_config(config['distribution'])
        
        UI.success("Configuration validation passed")
      end
      
      def self.validate_android_config(android_config)
        required_android_keys = ['application_id', 'keystore_path', 'key_alias', 'build_type']
        missing_keys = required_android_keys.select { |key| !android_config.key?(key) || android_config[key].to_s.empty? }
        
        unless missing_keys.empty?
          UI.user_error!("Missing required Android configuration keys: #{missing_keys.join(', ')}")
        end
        
        # Validate application_id format
        app_id = android_config['application_id']
        unless app_id.match?(/^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$/)
          UI.user_error!("Invalid Android application_id format: #{app_id}")
        end
        
        # Validate build_type
        valid_build_types = ['debug', 'release']
        unless valid_build_types.include?(android_config['build_type'])
          UI.user_error!("Invalid Android build_type. Must be one of: #{valid_build_types.join(', ')}")
        end
      end
      
      def self.validate_windows_config(windows_config)
        required_windows_keys = ['app_name', 'publisher', 'installer_type']
        missing_keys = required_windows_keys.select { |key| !windows_config.key?(key) || windows_config[key].to_s.empty? }
        
        unless missing_keys.empty?
          UI.user_error!("Missing required Windows configuration keys: #{missing_keys.join(', ')}")
        end
        
        # Validate installer_type
        valid_installer_types = ['msi', 'nsis']
        unless valid_installer_types.include?(windows_config['installer_type'])
          UI.user_error!("Invalid Windows installer_type. Must be one of: #{valid_installer_types.join(', ')}")
        end
      end
      
      def self.validate_linux_config(linux_config)
        required_linux_keys = ['app_name', 'desktop_entry', 'appimage']
        missing_keys = required_linux_keys.select { |key| !linux_config.key?(key) }
        
        unless missing_keys.empty?
          UI.user_error!("Missing required Linux configuration keys: #{missing_keys.join(', ')}")
        end
        
        # Validate desktop_entry
        desktop_entry = linux_config['desktop_entry']
        required_desktop_keys = ['name', 'comment', 'categories']
        missing_desktop_keys = required_desktop_keys.select { |key| !desktop_entry.key?(key) || desktop_entry[key].to_s.empty? }
        
        unless missing_desktop_keys.empty?
          UI.user_error!("Missing required Linux desktop_entry keys: #{missing_desktop_keys.join(', ')}")
        end
        
        # Validate appimage
        appimage = linux_config['appimage']
        required_appimage_keys = ['icon', 'app_id']
        missing_appimage_keys = required_appimage_keys.select { |key| !appimage.key?(key) || appimage[key].to_s.empty? }
        
        unless missing_appimage_keys.empty?
          UI.user_error!("Missing required Linux appimage keys: #{missing_appimage_keys.join(', ')}")
        end
      end
      
      def self.validate_flutter_config(flutter_config)
        required_flutter_keys = ['build_name', 'build_number', 'flavor']
        missing_keys = required_flutter_keys.select { |key| !flutter_config.key?(key) || flutter_config[key].to_s.empty? }
        
        unless missing_keys.empty?
          UI.user_error!("Missing required Flutter configuration keys: #{missing_keys.join(', ')}")
        end
        
        # Validate build_number
        valid_build_number_types = ['auto', 'manual']
        unless valid_build_number_types.include?(flutter_config['build_number']) || flutter_config['build_number'].to_i > 0
          UI.user_error!("Invalid Flutter build_number. Must be 'auto', 'manual', or a positive integer")
        end
        
        # Validate build_name format (semantic versioning)
        build_name = flutter_config['build_name']
        unless build_name.match?(/^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$/)
          UI.user_error!("Invalid Flutter build_name format. Must follow semantic versioning (e.g., 1.0.0 or 1.0.0-dev)")
        end
      end
      
      def self.validate_distribution_config(distribution_config)
        # Validate boolean values
        boolean_keys = ['google_play_internal', 'google_play_production', 'github_releases', 'auto_update']
        boolean_keys.each do |key|
          if distribution_config.key?(key) && ![true, false].include?(distribution_config[key])
            UI.user_error!("Distribution configuration '#{key}' must be true or false")
          end
        end
      end
      
      def self.setup_lane_context(config)
        # Set lane context variables for use in other actions
        Actions.lane_context[SharedValues::ENVIRONMENT_CONFIG] = config
        Actions.lane_context[SharedValues::CURRENT_ENVIRONMENT] = config['environment']
        Actions.lane_context[SharedValues::ANDROID_APP_ID] = config['android']['application_id']
        Actions.lane_context[SharedValues::FLUTTER_BUILD_NAME] = config['flutter']['build_name']
        Actions.lane_context[SharedValues::FLUTTER_FLAVOR] = config['flutter']['flavor']
        
        # Set environment variables for external tools
        ENV['FLUTTER_ENVIRONMENT'] = config['environment']
        ENV['ANDROID_APPLICATION_ID'] = config['android']['application_id']
        ENV['FLUTTER_BUILD_NAME'] = config['flutter']['build_name']
        ENV['FLUTTER_FLAVOR'] = config['flutter']['flavor']
        
        # Set Dart defines as environment variables
        if config['flutter']['dart_defines']
          config['flutter']['dart_defines'].each do |key, value|
            ENV["DART_DEFINE_#{key}"] = value.to_s
          end
        end
      end
      
      def self.display_configuration_summary(config)
        UI.header("Environment Configuration Summary")
        
        summary_table = {
          "Environment" => config['environment'],
          "Android App ID" => config['android']['application_id'],
          "Android Build Type" => config['android']['build_type'],
          "Windows App Name" => config['windows']['app_name'],
          "Linux App Name" => config['linux']['app_name'],
          "Flutter Build Name" => config['flutter']['build_name'],
          "Flutter Build Number" => config['flutter']['build_number'],
          "Flutter Flavor" => config['flutter']['flavor'],
          "Google Play Internal" => config['distribution']['google_play_internal'],
          "Google Play Production" => config['distribution']['google_play_production'],
          "GitHub Releases" => config['distribution']['github_releases']
        }
        
        FastlaneCore::PrintTable.print_values(
          config: summary_table,
          title: "Configuration Summary"
        )
      end
      
      def self.description
        "Load and validate environment-specific configuration for Fastlane builds"
      end
      
      def self.details
        "This action loads configuration from JSON files in the fastlane/config directory, " \
        "validates the configuration parameters, and sets up the environment for the build process. " \
        "It supports development, staging, and production environments with fallback to development."
      end
      
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :environment,
            env_name: "FASTLANE_ENVIRONMENT",
            description: "The environment to configure (development, staging, production)",
            optional: true,
            default_value: "development",
            verify_block: proc do |value|
              valid_environments = ['development', 'staging', 'production']
              unless valid_environments.include?(value)
                UI.user_error!("Invalid environment '#{value}'. Must be one of: #{valid_environments.join(', ')}")
              end
            end
          )
        ]
      end
      
      def self.output
        [
          ['ENVIRONMENT_CONFIG', 'The loaded environment configuration hash'],
          ['CURRENT_ENVIRONMENT', 'The current environment name'],
          ['ANDROID_APP_ID', 'The Android application ID'],
          ['FLUTTER_BUILD_NAME', 'The Flutter build name/version'],
          ['FLUTTER_FLAVOR', 'The Flutter flavor']
        ]
      end
      
      def self.return_value
        "Returns the loaded configuration hash"
      end
      
      def self.authors
        ["IoTeck Solutions"]
      end
      
      def self.is_supported?(platform)
        [:android, :ios].include?(platform)
      end
      
      def self.example_code
        [
          'setup_environment',
          'setup_environment(environment: "staging")',
          'config = setup_environment(environment: "production")'
        ]
      end
      
      def self.category
        :building
      end
    end
  end
end

# Define shared values for lane context
module Fastlane
  module Actions
    module SharedValues
      ENVIRONMENT_CONFIG = :ENVIRONMENT_CONFIG
      CURRENT_ENVIRONMENT = :CURRENT_ENVIRONMENT
      ANDROID_APP_ID = :ANDROID_APP_ID
      FLUTTER_BUILD_NAME = :FLUTTER_BUILD_NAME
      FLUTTER_FLAVOR = :FLUTTER_FLAVOR
    end
  end
end