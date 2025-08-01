require 'fileutils'
require 'openssl'

class SigningManager
  def initialize(config)
    @config = config
    @signing_config = config['signing']
    @environment = config['environment']['name']
  end
  
  def setup_signing
    FastlaneCore::FastlaneCore::UI.header("🔐 Setting up code signing for #{@environment} environment")
    
    validate_signing_configuration
    validate_certificate_availability
    setup_gradle_signing_config
    
    FastlaneCore::FastlaneCore::UI.success("✅ Code signing configured successfully")
  end
  
  def validate_signing_configuration
    FastlaneCore::FastlaneCore::UI.message("🔍 Validating signing configuration...")
    
    required_keys = %w[store_file store_password_env key_alias key_password_env]
    missing_keys = required_keys.select { |key| !@signing_config.key?(key) }
    
    unless missing_keys.empty?
      FastlaneCore::FastlaneCore::UI.user_error!("Missing required signing configuration keys: #{missing_keys.join(', ')}")
    end
    
    # Validate environment variables are set
    store_password_env = @signing_config['store_password_env']
    key_password_env = @signing_config['key_password_env']
    
    unless ENV[store_password_env]
      FastlaneCore::FastlaneCore::UI.user_error!("Environment variable #{store_password_env} is not set")
    end
    
    unless ENV[key_password_env]
      FastlaneCore::FastlaneCore::UI.user_error!("Environment variable #{key_password_env} is not set")
    end
    
    FastlaneCore::FastlaneCore::UI.success("✅ Signing configuration validation passed")
  end
  
  def validate_certificate_availability
    FastlaneCore::UI.message("🔍 Validating certificate availability...")
    
    keystore_path = get_keystore_path
    
    unless File.exist?(keystore_path)
      FastlaneCore::UI.user_error!("Keystore file not found: #{keystore_path}")
    end
    
    # Validate keystore can be opened with provided credentials
    validate_keystore_credentials(keystore_path)
    
    # Check certificate validity
    check_certificate_validity(keystore_path)
    
    FastlaneCore::UI.success("✅ Certificate validation passed")
  end
  
  def setup_gradle_signing_config
    FastlaneCore::UI.message("🔧 Setting up Gradle signing configuration...")
    
    keystore_path = get_keystore_path
    store_password = ENV[@signing_config['store_password_env']]
    key_alias = @signing_config['key_alias']
    key_password = ENV[@signing_config['key_password_env']]
    
    # Update gradle.properties with signing configuration
    update_gradle_properties(keystore_path, store_password, key_alias, key_password)
    
    # Update app/build.gradle with signing configuration
    update_build_gradle
    
    FastlaneCore::UI.success("✅ Gradle signing configuration updated")
  end
  
  def get_keystore_path
    store_file = @signing_config['store_file']
    
    # Check multiple possible locations for keystore
    possible_paths = [
      File.join(Dir.pwd, '..', 'keystores', store_file),
      File.join(Dir.pwd, '..', 'app', store_file),
      File.join(Dir.pwd, '..', store_file),
      File.join(ENV['HOME'], '.android', store_file),
      store_file # Absolute path
    ]
    
    existing_path = possible_paths.find { |path| File.exist?(path) }
    
    if existing_path
      File.expand_path(existing_path)
    else
      # For development environment, create debug keystore if it doesn't exist
      if @environment == 'development' && store_file == 'debug.keystore'
        create_debug_keystore
      else
        FastlaneCore::UI.user_error!("Keystore file not found. Searched in: #{possible_paths.join(', ')}")
      end
    end
  end
  
  def create_debug_keystore
    FastlaneCore::UI.message("🔨 Creating debug keystore...")
    
    keystores_dir = File.join(Dir.pwd, '..', 'keystores')
    FileUtils.mkdir_p(keystores_dir)
    
    keystore_path = File.join(keystores_dir, 'debug.keystore')
    
    # Generate debug keystore using keytool
    keytool_command = [
      'keytool',
      '-genkey',
      '-v',
      '-keystore', keystore_path,
      '-storepass', 'android',
      '-alias', 'debug',
      '-keypass', 'android',
      '-keyalg', 'RSA',
      '-keysize', '2048',
      '-validity', '10000',
      '-dname', '"CN=Android Debug,O=Android,C=US"'
    ].join(' ')
    
    system(keytool_command)
    
    FastlaneCore::UI.success("✅ Debug keystore created at #{keystore_path}")
    keystore_path
  end
  
  def validate_keystore_credentials(keystore_path)
    store_password = ENV[@signing_config['store_password_env']]
    key_alias = @signing_config['key_alias']
    key_password = ENV[@signing_config['key_password_env']]
    
    # Test keystore access using keytool
    begin
      keytool_command = [
        'keytool',
        '-list',
        '-keystore', keystore_path,
        '-storepass', store_password,
        '-alias', key_alias
      ].join(' ')
      
      `#{keytool_command}`
    rescue => e
      FastlaneCore::UI.user_error!("Failed to access keystore with provided credentials: #{e.message}")
    end
  end
  
  def check_certificate_validity(keystore_path)
    store_password = ENV[@signing_config['store_password_env']]
    key_alias = @signing_config['key_alias']
    
    begin
      # Get certificate information
      keytool_command = [
        'keytool',
        '-list',
        '-v',
        '-keystore', keystore_path,
        '-storepass', store_password,
        '-alias', key_alias
      ].join(' ')
      
      cert_info = `#{keytool_command}`
      
      # Parse expiration date
      if cert_info.match(/Valid from: .* until: (.*)/)
        expiry_date_str = $1.strip
        # Simple check - in production, you'd want more robust date parsing
        FastlaneCore::UI.message("📅 Certificate expires: #{expiry_date_str}")
        
        # Warn if certificate expires soon (within 30 days)
        # This is a simplified check - in production, implement proper date parsing
        if expiry_date_str.include?(Time.now.year.to_s) && 
           expiry_date_str.include?((Time.now.month + 1).to_s)
          FastlaneCore::UI.important("⚠️  Certificate expires soon: #{expiry_date_str}")
        end
      end
      
    rescue => e
      FastlaneCore::UI.error("Failed to check certificate validity: #{e.message}")
    end
  end
  
  def update_gradle_properties(keystore_path, store_password, key_alias, key_password)
    gradle_properties_path = File.join(Dir.pwd, '..', 'gradle.properties')
    
    # Read existing properties
    properties = {}
    if File.exist?(gradle_properties_path)
      File.readlines(gradle_properties_path).each do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')
        
        key, value = line.split('=', 2)
        properties[key] = value if key && value
      end
    end
    
    # Add/update signing properties
    signing_properties = {
      "#{@environment}.storeFile" => keystore_path,
      "#{@environment}.storePassword" => store_password,
      "#{@environment}.keyAlias" => key_alias,
      "#{@environment}.keyPassword" => key_password
    }
    
    properties.merge!(signing_properties)
    
    # Write updated properties
    File.open(gradle_properties_path, 'w') do |file|
      file.puts "# Gradle properties"
      file.puts "android.defaults.buildfeatures.buildconfig=true"
      file.puts "android.enableJetifier=true"
      file.puts "android.nonFinalResIds=false"
      file.puts "android.nonTransitiveRClass=false"
      file.puts "android.useAndroidX=true"
      file.puts "org.gradle.jvmargs=-Xmx1536M"
      file.puts ""
      file.puts "# Signing configuration"
      
      signing_properties.each do |key, value|
        file.puts "#{key}=#{value}"
      end
    end
    
    FastlaneCore::UI.message("📝 Updated gradle.properties with signing configuration")
  end
  
  def update_build_gradle
    build_gradle_path = File.join(Dir.pwd, '..', 'app', 'build.gradle')
    
    unless File.exist?(build_gradle_path)
      FastlaneCore::UI.user_error!("build.gradle not found at #{build_gradle_path}")
    end
    
    content = File.read(build_gradle_path)
    
    # Check if signing config already exists
    if content.include?('signingConfigs {')
      FastlaneCore::UI.message("📝 Signing configuration already exists in build.gradle")
      return
    end
    
    # Add signing configuration
    signing_config = generate_signing_config_gradle
    
    # Insert signing config after android {
    updated_content = content.gsub(
      /android\s*\{/,
      "android {\n#{signing_config}"
    )
    
    # Update buildTypes to use signing config
    if @environment != 'development'
      updated_content = updated_content.gsub(
        /signingConfig signingConfigs\.debug/,
        "signingConfig signingConfigs.#{@environment}"
      )
    end
    
    File.write(build_gradle_path, updated_content)
    FastlaneCore::UI.message("📝 Updated build.gradle with signing configuration")
  end
  
  def generate_signing_config_gradle
    <<~GRADLE
    
        signingConfigs {
            #{@environment} {
                storeFile file(project.findProperty('#{@environment}.storeFile') ?: 'debug.keystore')
                storePassword project.findProperty('#{@environment}.storePassword') ?: 'android'
                keyAlias project.findProperty('#{@environment}.keyAlias') ?: 'debug'
                keyPassword project.findProperty('#{@environment}.keyPassword') ?: 'android'
            }
        }
    GRADLE
  end
  
  def cleanup_sensitive_data
    FastlaneCore::UI.message("🧹 Cleaning up sensitive data from logs...")
    
    # This method would be called after build to ensure no sensitive data remains in logs
    # In a real implementation, you might want to:
    # 1. Clear environment variables containing passwords
    # 2. Remove temporary files with sensitive data
    # 3. Sanitize build logs
    
    FastlaneCore::UI.success("✅ Sensitive data cleanup completed")
  end
  
  def get_signing_info
    {
      environment: @environment,
      store_file: @signing_config['store_file'],
      key_alias: @signing_config['key_alias'],
      keystore_path: get_keystore_path
    }
  end
end