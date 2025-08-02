require 'date'
require 'openssl'

class CertificateValidator
  def initialize(keystore_path, store_password, key_alias)
    @keystore_path = keystore_path
    @store_password = store_password
    @key_alias = key_alias
  end
  
  def validate_certificate
    FastlaneCore::UI.header("🔍 Validating certificate details")
    
    cert_info = get_certificate_info
    validate_expiry(cert_info)
    validate_key_strength(cert_info)
    validate_signature_algorithm(cert_info)
    
    FastlaneCore::UI.success("✅ Certificate validation completed")
    cert_info
  end
  
  def get_certificate_info
    FastlaneCore::UI.message("📋 Retrieving certificate information...")
    
    begin
      keytool_command = [
        'keytool',
        '-list',
        '-v',
        '-keystore', @keystore_path,
        '-storepass', @store_password,
        '-alias', @key_alias
      ].join(' ')
      
      cert_output = `#{keytool_command}`
      parse_certificate_info(cert_output)
      
    rescue => e
      FastlaneCore::UI.user_error!("Failed to retrieve certificate information: #{e.message}")
    end
  end
  
  def parse_certificate_info(cert_output)
    info = {}
    
    # Parse certificate details from keytool output
    cert_output.each_line do |line|
      line = line.strip
      
      case line
      when /Owner: (.*)/
        info[:owner] = $1
      when /Issuer: (.*)/
        info[:issuer] = $1
      when /Serial number: (.*)/
        info[:serial_number] = $1
      when /Valid from: (.*) until: (.*)/
        info[:valid_from] = $1.strip
        info[:valid_until] = $2.strip
      when /Certificate fingerprints:/
        # Next lines will contain fingerprints
      when /SHA1: (.*)/
        info[:sha1_fingerprint] = $1
      when /SHA256: (.*)/
        info[:sha256_fingerprint] = $1
      when /Signature algorithm name: (.*)/
        info[:signature_algorithm] = $1
      when /Subject Public Key Algorithm: (.*)/
        info[:key_algorithm] = $1
      when /Version: (.*)/
        info[:version] = $1
      end
    end
    
    info
  end
  
  def validate_expiry(cert_info)
    FastlaneCore::UI.message("📅 Validating certificate expiry...")
    
    return unless cert_info[:valid_until]
    
    begin
      # Parse the date string (format may vary)
      expiry_str = cert_info[:valid_until]
      
      # Try different date formats
      expiry_date = nil
      date_formats = [
        '%a %b %d %H:%M:%S %Z %Y',  # Tue Jan 01 00:00:00 UTC 2025
        '%Y-%m-%d %H:%M:%S',        # 2025-01-01 00:00:00
        '%m/%d/%Y %H:%M:%S',        # 01/01/2025 00:00:00
        '%d/%m/%Y %H:%M:%S'         # 01/01/2025 00:00:00
      ]
      
      date_formats.each do |format|
        begin
          expiry_date = DateTime.strptime(expiry_str, format)
          break
        rescue ArgumentError
          next
        end
      end
      
      if expiry_date.nil?
        FastlaneCore::UI.important("⚠️  Could not parse expiry date: #{expiry_str}")
        return
      end
      
      days_until_expiry = (expiry_date - DateTime.now).to_i
      
      if days_until_expiry < 0
        FastlaneCore::UI.user_error!("❌ Certificate has expired on #{expiry_str}")
      elsif days_until_expiry < 30
        FastlaneCore::UI.important("⚠️  Certificate expires in #{days_until_expiry} days (#{expiry_str})")
      elsif days_until_expiry < 90
        FastlaneCore::UI.message("📅 Certificate expires in #{days_until_expiry} days (#{expiry_str})")
      else
        FastlaneCore::UI.success("✅ Certificate is valid until #{expiry_str} (#{days_until_expiry} days)")
      end
      
    rescue => e
      FastlaneCore::UI.important("⚠️  Could not validate expiry date: #{e.message}")
    end
  end
  
  def validate_key_strength(cert_info)
    FastlaneCore::UI.message("🔐 Validating key strength...")
    
    # Extract key size from certificate info
    # This is a simplified check - in production, you'd want more robust parsing
    if cert_info[:key_algorithm]
      algorithm = cert_info[:key_algorithm].downcase
      
      if algorithm.include?('rsa')
        # For RSA, check if it's at least 2048 bits
        if algorithm.include?('2048') || algorithm.include?('4096')
          FastlaneCore::UI.success("✅ RSA key strength is adequate")
        elsif algorithm.include?('1024')
          FastlaneCore::UI.important("⚠️  RSA 1024-bit key is weak, consider upgrading to 2048-bit or higher")
        else
          FastlaneCore::UI.message("📋 RSA key detected, strength unknown")
        end
      elsif algorithm.include?('ec') || algorithm.include?('ecdsa')
        FastlaneCore::UI.success("✅ ECDSA key detected (generally strong)")
      else
        FastlaneCore::UI.message("📋 Key algorithm: #{cert_info[:key_algorithm]}")
      end
    end
  end
  
  def validate_signature_algorithm(cert_info)
    FastlaneCore::UI.message("🔏 Validating signature algorithm...")
    
    return unless cert_info[:signature_algorithm]
    
    algorithm = cert_info[:signature_algorithm].downcase
    
    # Check for weak signature algorithms
    weak_algorithms = ['md5', 'sha1withrsaencryption', 'sha1withdsa']
    strong_algorithms = ['sha256withrsa', 'sha256withecdsa', 'sha384withrsa', 'sha512withrsa']
    
    if weak_algorithms.any? { |weak| algorithm.include?(weak) }
      FastlaneCore::UI.important("⚠️  Weak signature algorithm detected: #{cert_info[:signature_algorithm]}")
      FastlaneCore::UI.important("    Consider regenerating certificate with SHA-256 or higher")
    elsif strong_algorithms.any? { |strong| algorithm.include?(strong) }
      FastlaneCore::UI.success("✅ Strong signature algorithm: #{cert_info[:signature_algorithm]}")
    else
      FastlaneCore::UI.message("📋 Signature algorithm: #{cert_info[:signature_algorithm]}")
    end
  end
  
  def generate_certificate_report(cert_info)
    FastlaneCore::UI.header("📋 Certificate Report")
    
    report = []
    report << "Certificate Information:"
    report << "  Owner: #{cert_info[:owner] || 'Unknown'}"
    report << "  Issuer: #{cert_info[:issuer] || 'Unknown'}"
    report << "  Serial Number: #{cert_info[:serial_number] || 'Unknown'}"
    report << "  Valid From: #{cert_info[:valid_from] || 'Unknown'}"
    report << "  Valid Until: #{cert_info[:valid_until] || 'Unknown'}"
    report << "  Key Algorithm: #{cert_info[:key_algorithm] || 'Unknown'}"
    report << "  Signature Algorithm: #{cert_info[:signature_algorithm] || 'Unknown'}"
    report << "  SHA1 Fingerprint: #{cert_info[:sha1_fingerprint] || 'Unknown'}"
    report << "  SHA256 Fingerprint: #{cert_info[:sha256_fingerprint] || 'Unknown'}"
    
    report.each { |line| FastlaneCore::UI.message(line) }
    
    # Save report to file
    report_path = File.join(Dir.pwd, '..', '..', 'build', 'certificate-report.txt')
    FileUtils.mkdir_p(File.dirname(report_path))
    File.write(report_path, report.join("\n"))
    
    FastlaneCore::UI.success("📄 Certificate report saved to #{report_path}")
    
    cert_info
  end
  
  def self.validate_environment_certificates(environments = ['development', 'staging', 'production'])
    FastlaneCore::UI.header("🔍 Validating certificates for all environments")
    
    results = {}
    
    environments.each do |env|
      begin
        FastlaneCore::UI.message("Checking #{env} environment...")
        
        # Load environment config
        config_path = File.join(Dir.pwd, '..', '..', 'config', 'environments', "#{env}.yaml")
        next unless File.exist?(config_path)
        
        config = YAML.load_file(config_path)
        signing_config = config['signing']
        
        # Get keystore path
        signing_manager = SigningManager.new(config)
        keystore_path = signing_manager.get_keystore_path
        
        # Validate certificate
        store_password = ENV[signing_config['store_password_env']] || 'android'
        key_alias = signing_config['key_alias']
        
        validator = CertificateValidator.new(keystore_path, store_password, key_alias)
        cert_info = validator.validate_certificate
        
        results[env] = {
          status: 'valid',
          certificate_info: cert_info
        }
        
      rescue => e
        FastlaneCore::UI.error("❌ Certificate validation failed for #{env}: #{e.message}")
        results[env] = {
          status: 'invalid',
          error: e.message
        }
      end
    end
    
    # Generate summary report
    generate_summary_report(results)
    
    results
  end
  
  def self.generate_summary_report(results)
    FastlaneCore::UI.header("📊 Certificate Validation Summary")
    
    results.each do |env, result|
      if result[:status] == 'valid'
        FastlaneCore::UI.success("✅ #{env.capitalize}: Certificate is valid")
      else
        FastlaneCore::UI.error("❌ #{env.capitalize}: #{result[:error]}")
      end
    end
    
    # Save summary to file
    summary_path = File.join(Dir.pwd, '..', '..', 'build', 'certificate-summary.json')
    FileUtils.mkdir_p(File.dirname(summary_path))
    File.write(summary_path, JSON.pretty_generate(results))
    
    FastlaneCore::UI.success("📄 Certificate summary saved to #{summary_path}")
  end
  
  def validate_certificate_chain
    FastlaneCore::UI.message("🔗 Validating certificate chain...")
    
    begin
      keytool_command = [
        'keytool',
        '-list',
        '-v',
        '-keystore', @keystore_path,
        '-storepass', @store_password,
        '-alias', @key_alias
      ].join(' ')
      
      cert_output = `#{keytool_command}`
      
      # Check for certificate chain
      if cert_output.include?('Certificate chain length:')
        chain_length = cert_output.match(/Certificate chain length: (\d+)/)[1].to_i
        
        if chain_length == 1
          FastlaneCore::UI.message("📋 Self-signed certificate (chain length: 1)")
        else
          FastlaneCore::UI.success("✅ Certificate chain length: #{chain_length}")
        end
      end
      
      # Check for trusted certificate authorities
      if cert_output.include?('Issuer:')
        issuer = cert_output.match(/Issuer: (.*)/)[1]
        
        # Check for well-known CAs
        trusted_cas = [
          'DigiCert', 'VeriSign', 'Symantec', 'GeoTrust', 'Thawte',
          'GlobalSign', 'Comodo', 'Entrust', 'Let\'s Encrypt'
        ]
        
        is_trusted = trusted_cas.any? { |ca| issuer.include?(ca) }
        
        if is_trusted
          FastlaneCore::UI.success("✅ Certificate issued by trusted CA")
        elsif issuer.include?('CN=Android Debug')
          FastlaneCore::UI.message("📋 Debug certificate (self-signed)")
        else
          FastlaneCore::UI.message("📋 Certificate issuer: #{issuer}")
        end
      end
      
    rescue => e
      FastlaneCore::UI.important("⚠️  Could not validate certificate chain: #{e.message}")
    end
  end
  
  def check_certificate_revocation
    FastlaneCore::UI.message("🔍 Checking certificate revocation status...")
    
    # This is a simplified check - in production, you'd want to implement
    # proper OCSP or CRL checking
    FastlaneCore::UI.message("📋 Certificate revocation checking not implemented")
    FastlaneCore::UI.message("    Consider implementing OCSP validation for production certificates")
  end
  
  def validate_certificate_usage
    FastlaneCore::UI.message("🔍 Validating certificate usage...")
    
    begin
      keytool_command = [
        'keytool',
        '-list',
        '-v',
        '-keystore', @keystore_path,
        '-storepass', @store_password,
        '-alias', @key_alias
      ].join(' ')
      
      cert_output = `#{keytool_command}`
      
      # Check key usage extensions
      if cert_output.include?('KeyUsage')
        key_usage = cert_output.match(/KeyUsage \[([^\]]+)\]/)[1]
        FastlaneCore::UI.message("📋 Key Usage: #{key_usage}")
        
        # Check for code signing usage
        if key_usage.include?('DigitalSignature')
          FastlaneCore::UI.success("✅ Certificate supports digital signatures")
        else
          FastlaneCore::UI.important("⚠️  Certificate may not support digital signatures")
        end
      end
      
      # Check extended key usage
      if cert_output.include?('ExtendedKeyUsage')
        ext_key_usage = cert_output.match(/ExtendedKeyUsage \[([^\]]+)\]/)[1]
        FastlaneCore::UI.message("📋 Extended Key Usage: #{ext_key_usage}")
        
        if ext_key_usage.include?('CodeSigning')
          FastlaneCore::UI.success("✅ Certificate supports code signing")
        end
      end
      
    rescue => e
      FastlaneCore::UI.important("⚠️  Could not validate certificate usage: #{e.message}")
    end
  end
  
  def comprehensive_validation
    FastlaneCore::UI.header("🔍 Comprehensive Certificate Validation")
    
    # Run all validation checks
    cert_info = validate_certificate
    validate_certificate_chain
    validate_certificate_usage
    check_certificate_revocation
    
    # Generate comprehensive report
    generate_comprehensive_report(cert_info)
    
    cert_info
  end
  
  def generate_comprehensive_report(cert_info)
    FastlaneCore::UI.header("📋 Comprehensive Certificate Report")
    
    report = {
      timestamp: Time.now.iso8601,
      keystore_path: @keystore_path,
      key_alias: @key_alias,
      certificate_info: cert_info,
      validation_results: {
        basic_validation: 'completed',
        chain_validation: 'completed',
        usage_validation: 'completed',
        revocation_check: 'skipped'
      }
    }
    
    # Save comprehensive report
    report_path = File.join(Dir.pwd, '..', '..', 'build', 'comprehensive-certificate-report.json')
    FileUtils.mkdir_p(File.dirname(report_path))
    File.write(report_path, JSON.pretty_generate(report))
    
    FastlaneCore::UI.success("📄 Comprehensive certificate report saved to #{report_path}")
    
    report
  end
end