require 'base64'
require 'openssl'

class CredentialManager
  def initialize(environment)
    @environment = environment
  end
  
  def validate_environment_variables(signing_config)
    FastlaneCore::UI.header("🔐 Validating signing credentials")
    
    required_env_vars = [
      signing_config['store_password_env'],
      signing_config['key_password_env']
    ]
    
    missing_vars = []
    empty_vars = []
    
    required_env_vars.each do |var_name|
      if ENV[var_name].nil?
        missing_vars << var_name
      elsif ENV[var_name].empty?
        empty_vars << var_name
      end
    end
    
    unless missing_vars.empty?
      FastlaneCore::UI.user_error!("Missing required environment variables: #{missing_vars.join(', ')}")
    end
    
    unless empty_vars.empty?
      FastlaneCore::UI.user_error!("Empty environment variables: #{empty_vars.join(', ')}")
    end
    
    # Validate password strength (basic check)
    validate_password_strength(signing_config)
    
    FastlaneCore::UI.success("✅ All required credentials are available")
  end
  
  def validate_password_strength(signing_config)
    store_password = ENV[signing_config['store_password_env']]
    key_password = ENV[signing_config['key_password_env']]
    
    # Skip validation for development environment (uses default debug passwords)
    return if @environment == 'development'
    
    passwords = {
      'Store Password' => store_password,
      'Key Password' => key_password
    }
    
    passwords.each do |name, password|
      if password.length < 8
        FastlaneCore::UI.important("⚠️  #{name} is shorter than 8 characters")
      end
      
      if password == 'android' || password == 'password' || password == '123456'
        FastlaneCore::UI.important("⚠️  #{name} appears to be a default/weak password")
      end
      
      # Check for basic complexity
      has_upper = password.match?(/[A-Z]/)
      has_lower = password.match?(/[a-z]/)
      has_digit = password.match?(/[0-9]/)
      has_special = password.match?(/[^A-Za-z0-9]/)
      
      complexity_score = [has_upper, has_lower, has_digit, has_special].count(true)
      
      if complexity_score < 3 && @environment == 'production'
        FastlaneCore::UI.important("⚠️  #{name} has low complexity for production environment")
      end
    end
  end
  
  def setup_secure_environment
    FastlaneCore::UI.message("🔒 Setting up secure environment for signing")
    
    # Set secure file permissions for keystore directory
    keystores_dir = File.join(Dir.pwd, '..', 'keystores')
    if Dir.exist?(keystores_dir)
      begin
        File.chmod(0700, keystores_dir)  # Owner read/write/execute only
        
        Dir.glob(File.join(keystores_dir, '*.keystore')).each do |keystore|
          File.chmod(0600, keystore)  # Owner read/write only
        end
        
        FastlaneCore::UI.success("✅ Secure file permissions set for keystores")
      rescue => e
        FastlaneCore::UI.important("⚠️  Could not set secure file permissions: #{e.message}")
      end
    end
    
    # Clear any previous signing-related environment variables that might leak
    clear_previous_signing_vars
  end
  
  def clear_previous_signing_vars
    # Clear any environment variables that might contain sensitive data from previous runs
    signing_vars = ENV.keys.select { |key| key.include?('SIGNING') || key.include?('KEYSTORE') }
    
    signing_vars.each do |var|
      next if var.end_with?('_ENV')  # Keep the variable name references
      ENV.delete(var)
    end
  end
  
  def load_credentials_from_file(credentials_file)
    FastlaneCore::UI.message("📂 Loading credentials from secure file")
    
    unless File.exist?(credentials_file)
      FastlaneCore::UI.user_error!("Credentials file not found: #{credentials_file}")
    end
    
    # Ensure file has secure permissions
    file_stat = File.stat(credentials_file)
    if file_stat.mode & 0077 != 0  # Check if group/other have any permissions
      FastlaneCore::UI.user_error!("Credentials file has insecure permissions. Use: chmod 600 #{credentials_file}")
    end
    
    begin
      credentials = YAML.load_file(credentials_file)
      
      # Validate structure
      unless credentials.is_a?(Hash) && credentials[@environment]
        FastlaneCore::UI.user_error!("Invalid credentials file structure for environment: #{@environment}")
      end
      
      env_credentials = credentials[@environment]
      
      # Set environment variables from file
      env_credentials.each do |key, value|
        ENV[key] = value
      end
      
      FastlaneCore::UI.success("✅ Credentials loaded from file")
      
    rescue => e
      FastlaneCore::UI.user_error!("Failed to load credentials: #{e.message}")
    end
  end
  
  def generate_credentials_template
    FastlaneCore::UI.message("📝 Generating credentials template")
    
    template = {
      'development' => {
        'DEBUG_STORE_PASSWORD' => 'android',
        'DEBUG_KEY_PASSWORD' => 'android'
      },
      'staging' => {
        'STAGING_STORE_PASSWORD' => 'your-staging-store-password',
        'STAGING_KEY_PASSWORD' => 'your-staging-key-password'
      },
      'production' => {
        'RELEASE_STORE_PASSWORD' => 'your-production-store-password',
        'RELEASE_KEY_PASSWORD' => 'your-production-key-password'
      }
    }
    
    template_path = File.join(Dir.pwd, '..', 'credentials.yaml.template')
    File.write(template_path, YAML.dump(template))
    
    # Set secure permissions
    File.chmod(0600, template_path)
    
    FastlaneCore::UI.success("📄 Credentials template created at #{template_path}")
    FastlaneCore::UI.important("⚠️  Copy this to credentials.yaml and update with your actual passwords")
    FastlaneCore::UI.important("⚠️  Add credentials.yaml to .gitignore to prevent committing secrets")
    
    template_path
  end
  
  def encrypt_credentials(credentials_file, output_file, encryption_key)
    FastlaneCore::UI.message("🔐 Encrypting credentials file")
    
    unless File.exist?(credentials_file)
      FastlaneCore::UI.user_error!("Credentials file not found: #{credentials_file}")
    end
    
    begin
      # Read credentials
      credentials_content = File.read(credentials_file)
      
      # Validate credentials format before encryption
      begin
        YAML.load(credentials_content)
      rescue => e
        FastlaneCore::UI.user_error!("Invalid YAML format in credentials file: #{e.message}")
      end
      
      # Encrypt using AES-256-GCM for authenticated encryption
      cipher = OpenSSL::Cipher.new('AES-256-GCM')
      cipher.encrypt
      cipher.key = Digest::SHA256.digest(encryption_key)
      iv = cipher.random_iv
      
      encrypted_data = cipher.update(credentials_content) + cipher.final
      auth_tag = cipher.auth_tag
      
      # Combine IV, auth tag, and encrypted data
      combined_data = iv + auth_tag + encrypted_data
      encoded_data = Base64.strict_encode64(combined_data)
      
      # Add metadata header
      metadata = {
        version: '1.0',
        algorithm: 'AES-256-GCM',
        created_at: Time.now.iso8601,
        created_by: ENV['USER'] || ENV['USERNAME'] || 'unknown'
      }
      
      output_content = "# Encrypted credentials - #{metadata.to_json}\n#{encoded_data}"
      
      File.write(output_file, output_content)
      File.chmod(0600, output_file)
      
      FastlaneCore::UI.success("✅ Credentials encrypted and saved to #{output_file}")
      FastlaneCore::UI.message("🔒 Using AES-256-GCM authenticated encryption")
      
    rescue => e
      FastlaneCore::UI.user_error!("Failed to encrypt credentials: #{e.message}")
    end
  end
  
  def decrypt_credentials(encrypted_file, encryption_key)
    FastlaneCore::UI.message("🔓 Decrypting credentials")
    
    unless File.exist?(encrypted_file)
      FastlaneCore::UI.user_error!("Encrypted credentials file not found: #{encrypted_file}")
    end
    
    begin
      # Read encrypted file
      file_content = File.read(encrypted_file)
      
      # Extract metadata and encrypted data
      if file_content.start_with?('# Encrypted credentials')
        lines = file_content.split("\n")
        metadata_line = lines[0]
        encoded_data = lines[1..-1].join("\n")
        
        # Parse metadata
        metadata_json = metadata_line.match(/# Encrypted credentials - (.+)$/)[1]
        metadata = JSON.parse(metadata_json)
        
        FastlaneCore::UI.message("📋 Decrypting file created at #{metadata['created_at']} by #{metadata['created_by']}")
        
        # Check algorithm compatibility
        unless metadata['algorithm'] == 'AES-256-GCM'
          FastlaneCore::UI.user_error!("Unsupported encryption algorithm: #{metadata['algorithm']}")
        end
      else
        # Legacy format without metadata
        encoded_data = file_content
        FastlaneCore::UI.important("⚠️  Using legacy decryption format")
      end
      
      combined_data = Base64.strict_decode64(encoded_data)
      
      if metadata && metadata['algorithm'] == 'AES-256-GCM'
        # Extract IV, auth tag, and encrypted data for GCM
        iv = combined_data[0, 12]  # GCM uses 12-byte IV
        auth_tag = combined_data[12, 16]  # 16-byte auth tag
        encrypted_data = combined_data[28..-1]
        
        # Decrypt with authentication
        decipher = OpenSSL::Cipher.new('AES-256-GCM')
        decipher.decrypt
        decipher.key = Digest::SHA256.digest(encryption_key)
        decipher.iv = iv
        decipher.auth_tag = auth_tag
        
        decrypted_content = decipher.update(encrypted_data) + decipher.final
      else
        # Legacy CBC decryption
        iv = combined_data[0, 16]  # AES block size is 16 bytes
        encrypted_data = combined_data[16..-1]
        
        decipher = OpenSSL::Cipher.new('AES-256-CBC')
        decipher.decrypt
        decipher.key = Digest::SHA256.digest(encryption_key)
        decipher.iv = iv
        
        decrypted_content = decipher.update(encrypted_data) + decipher.final
      end
      
      # Parse and validate credentials
      credentials = YAML.load(decrypted_content)
      
      unless credentials.is_a?(Hash)
        FastlaneCore::UI.user_error!("Invalid credentials format after decryption")
      end
      
      if credentials[@environment]
        credentials[@environment].each do |key, value|
          ENV[key] = value
        end
        
        FastlaneCore::UI.success("✅ Credentials decrypted and loaded for #{@environment}")
      else
        FastlaneCore::UI.user_error!("No credentials found for environment: #{@environment}")
      end
      
    rescue OpenSSL::Cipher::CipherError => e
      FastlaneCore::UI.user_error!("Decryption failed - invalid encryption key or corrupted file: #{e.message}")
    rescue JSON::ParserError => e
      FastlaneCore::UI.user_error!("Failed to parse metadata: #{e.message}")
    rescue => e
      FastlaneCore::UI.user_error!("Failed to decrypt credentials: #{e.message}")
    end
  end
  
  def audit_credential_access
    FastlaneCore::UI.message("📊 Auditing credential access")
    
    audit_info = {
      timestamp: Time.now.iso8601,
      environment: @environment,
      user: ENV['USER'] || ENV['USERNAME'] || 'unknown',
      hostname: `hostname`.strip,
      working_directory: Dir.pwd,
      git_commit: get_git_commit,
      ci_environment: detect_ci_environment
    }
    
    # Save audit log
    audit_dir = File.join(Dir.pwd, '..', '..', 'build', 'audit')
    FileUtils.mkdir_p(audit_dir)
    
    audit_file = File.join(audit_dir, "signing-audit-#{Time.now.strftime('%Y%m%d')}.json")
    
    # Append to daily audit log
    existing_logs = []
    if File.exist?(audit_file)
      existing_logs = JSON.parse(File.read(audit_file))
    end
    
    existing_logs << audit_info
    File.write(audit_file, JSON.pretty_generate(existing_logs))
    
    FastlaneCore::UI.success("📋 Credential access logged to #{audit_file}")
    
    audit_info
  end
  
  def get_git_commit
    begin
      `git rev-parse HEAD`.strip
    rescue
      'unknown'
    end
  end
  
  def detect_ci_environment
    ci_indicators = {
      'GitHub Actions' => ENV['GITHUB_ACTIONS'],
      'GitLab CI' => ENV['GITLAB_CI'],
      'Jenkins' => ENV['JENKINS_URL'],
      'CircleCI' => ENV['CIRCLECI'],
      'Travis CI' => ENV['TRAVIS'],
      'Azure DevOps' => ENV['AZURE_HTTP_USER_AGENT']
    }
    
    ci_indicators.each do |name, indicator|
      return name if indicator
    end
    
    'local'
  end
  
  def cleanup_credentials
    FastlaneCore::UI.message("🧹 Cleaning up credentials from memory")
    
    # Clear environment variables containing sensitive data
    sensitive_vars = ENV.keys.select do |key|
      key.include?('PASSWORD') || 
      key.include?('SECRET') || 
      key.include?('KEY') ||
      key.include?('TOKEN')
    end
    
    # Don't clear the environment variable names, just the values
    sensitive_vars.each do |var|
      next if var.end_with?('_ENV')  # Keep variable name references
      ENV[var] = '' if ENV[var]
    end
    
    FastlaneCore::UI.success("✅ Sensitive credentials cleared from memory")
  end
  
  def self.setup_ci_credentials(environment)
    FastlaneCore::UI.header("🔧 Setting up CI/CD credentials for #{environment}")
    
    credential_manager = CredentialManager.new(environment)
    
    # Check if running in CI environment
    ci_env = credential_manager.detect_ci_environment
    
    if ci_env == 'local'
      FastlaneCore::UI.message("Running locally - credentials should be set manually")
      return
    end
    
    FastlaneCore::UI.message("Detected CI environment: #{ci_env}")
    
    # For CI environments, credentials should come from secure environment variables
    # This method validates they are properly set
    
    case environment
    when 'development'
      # Development can use default debug credentials
      ENV['DEBUG_STORE_PASSWORD'] ||= 'android'
      ENV['DEBUG_KEY_PASSWORD'] ||= 'android'
    when 'staging'
      required_vars = ['STAGING_STORE_PASSWORD', 'STAGING_KEY_PASSWORD']
      credential_manager.validate_required_ci_vars(required_vars)
    when 'production'
      required_vars = ['RELEASE_STORE_PASSWORD', 'RELEASE_KEY_PASSWORD']
      credential_manager.validate_required_ci_vars(required_vars)
    end
    
    FastlaneCore::UI.success("✅ CI credentials validated for #{environment}")
  end
  
  def validate_required_ci_vars(required_vars)
    missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }
    
    unless missing_vars.empty?
      FastlaneCore::UI.user_error!("Missing required CI environment variables: #{missing_vars.join(', ')}")
    end
  end
  
  def validate_keystore_integrity(keystore_path, store_password)
    FastlaneCore::UI.message("🔍 Validating keystore integrity...")
    
    begin
      # Check file exists and is readable
      unless File.exist?(keystore_path)
        FastlaneCore::UI.user_error!("Keystore file not found: #{keystore_path}")
      end
      
      unless File.readable?(keystore_path)
        FastlaneCore::UI.user_error!("Keystore file is not readable: #{keystore_path}")
      end
      
      # Check file size (empty keystore would be suspicious)
      file_size = File.size(keystore_path)
      if file_size < 1000  # Keystores are typically several KB
        FastlaneCore::UI.important("⚠️  Keystore file seems unusually small (#{file_size} bytes)")
      end
      
      # Verify keystore can be opened
      keytool_command = [
        'keytool',
        '-list',
        '-keystore', keystore_path,
        '-storepass', store_password,
        '-v'
      ].join(' ')
      
      result = `#{keytool_command} 2>&1`
      
      if $?.exitstatus != 0
        FastlaneCore::UI.user_error!("Failed to open keystore: #{result}")
      end
      
      # Check for multiple aliases (could indicate shared keystore)
      alias_count = result.scan(/Alias name:/).length
      if alias_count > 1
        FastlaneCore::UI.message("📋 Keystore contains #{alias_count} aliases")
      end
      
      FastlaneCore::UI.success("✅ Keystore integrity validation passed")
      
    rescue => e
      FastlaneCore::UI.user_error!("Keystore integrity validation failed: #{e.message}")
    end
  end
  
  def check_credential_exposure
    FastlaneCore::UI.message("🔍 Checking for credential exposure...")
    
    exposed_vars = []
    
    # Check environment variables that might contain sensitive data
    ENV.each do |key, value|
      next unless value && !value.empty?
      
      # Skip checking the environment variable name references
      next if key.end_with?('_ENV')
      
      if key.include?('PASSWORD') || key.include?('SECRET') || key.include?('KEY')
        # Check if value looks like a real password (not placeholder)
        if value.length > 6 && 
           !value.include?('your_') && 
           !value.include?('placeholder') &&
           !value.include?('example')
          
          # Check if it's not the default debug password
          unless value == 'android' && @environment == 'development'
            exposed_vars << key
          end
        end
      end
    end
    
    if exposed_vars.empty?
      FastlaneCore::UI.success("✅ No credential exposure detected")
    else
      FastlaneCore::UI.important("⚠️  Found #{exposed_vars.length} environment variables with potential credentials")
      FastlaneCore::UI.important("    Variables: #{exposed_vars.join(', ')}")
      FastlaneCore::UI.important("    Ensure these are properly secured in CI/CD")
    end
    
    exposed_vars
  end
  
  def generate_security_report
    FastlaneCore::UI.header("🛡️  Generating security report")
    
    report = {
      timestamp: Time.now.iso8601,
      environment: @environment,
      security_checks: {}
    }
    
    # Check credential exposure
    exposed_vars = check_credential_exposure
    report[:security_checks][:credential_exposure] = {
      status: exposed_vars.empty? ? 'pass' : 'warning',
      exposed_variables: exposed_vars
    }
    
    # Check file permissions
    keystores_dir = File.join(Dir.pwd, '..', 'keystores')
    if Dir.exist?(keystores_dir)
      keystore_files = Dir.glob(File.join(keystores_dir, '*.keystore'))
      insecure_files = []
      
      keystore_files.each do |keystore|
        stat = File.stat(keystore)
        # Check if group or others have any permissions
        if (stat.mode & 0077) != 0
          insecure_files << keystore
        end
      end
      
      report[:security_checks][:file_permissions] = {
        status: insecure_files.empty? ? 'pass' : 'fail',
        insecure_files: insecure_files
      }
    end
    
    # Check CI environment security
    ci_env = detect_ci_environment
    report[:security_checks][:ci_environment] = {
      detected: ci_env,
      is_secure: ci_env != 'local'
    }
    
    # Save report
    report_dir = File.join(Dir.pwd, '..', '..', 'build', 'security')
    FileUtils.mkdir_p(report_dir)
    
    report_file = File.join(report_dir, "security-report-#{Time.now.strftime('%Y%m%d-%H%M%S')}.json")
    File.write(report_file, JSON.pretty_generate(report))
    
    FastlaneCore::UI.success("🛡️  Security report saved to #{report_file}")
    
    # Display summary
    report[:security_checks].each do |check, result|
      case result[:status]
      when 'pass'
        FastlaneCore::UI.success("✅ #{check.to_s.gsub('_', ' ').capitalize}: PASS")
      when 'warning'
        FastlaneCore::UI.important("⚠️  #{check.to_s.gsub('_', ' ').capitalize}: WARNING")
      when 'fail'
        FastlaneCore::UI.error("❌ #{check.to_s.gsub('_', ' ').capitalize}: FAIL")
      end
    end
    
    report
  end
end