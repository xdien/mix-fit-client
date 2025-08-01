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
      
      # Encrypt using AES
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt
      cipher.key = Digest::SHA256.digest(encryption_key)
      iv = cipher.random_iv
      
      encrypted_data = cipher.update(credentials_content) + cipher.final
      
      # Combine IV and encrypted data
      combined_data = iv + encrypted_data
      encoded_data = Base64.strict_encode64(combined_data)
      
      File.write(output_file, encoded_data)
      File.chmod(0600, output_file)
      
      FastlaneCore::UI.success("✅ Credentials encrypted and saved to #{output_file}")
      
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
      # Read and decode encrypted data
      encoded_data = File.read(encrypted_file)
      combined_data = Base64.strict_decode64(encoded_data)
      
      # Extract IV and encrypted data
      iv = combined_data[0, 16]  # AES block size is 16 bytes
      encrypted_data = combined_data[16..-1]
      
      # Decrypt
      decipher = OpenSSL::Cipher.new('AES-256-CBC')
      decipher.decrypt
      decipher.key = Digest::SHA256.digest(encryption_key)
      decipher.iv = iv
      
      decrypted_content = decipher.update(encrypted_data) + decipher.final
      
      # Parse and set environment variables
      credentials = YAML.load(decrypted_content)
      
      if credentials[@environment]
        credentials[@environment].each do |key, value|
          ENV[key] = value
        end
        
        FastlaneCore::UI.success("✅ Credentials decrypted and loaded")
      else
        FastlaneCore::UI.user_error!("No credentials found for environment: #{@environment}")
      end
      
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
end