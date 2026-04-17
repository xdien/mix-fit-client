require 'fileutils'
require 'json'
require 'digest'
require 'time'

class ArtifactManager
  def initialize(config, build_type)
    @config = config
    @build_type = build_type
    @environment = config['environment']['name']
    @app_name = config['app']['name']
    @version_name = config['app']['version_name'] || '1.0.0'
    @version_code = config['app']['version_code'] || 1
    @build_time = Time.now
  end
  
  def organize_build_artifacts
    puts "📦 Organizing build artifacts for #{@environment}"
    
    # Create structured directory
    build_dir = create_build_directory
    
    # Process APK files
    apk_info = process_apk_files(build_dir)
    
    # Process AAB files
    aab_info = process_aab_files(build_dir)
    
    # Generate build metadata
    metadata = generate_build_metadata(apk_info, aab_info)
    
    # Create build info JSON
    create_build_info_file(build_dir, metadata)
    
    # Generate checksums
    generate_checksums(build_dir)
    
    # Validate artifacts
    validate_artifacts(build_dir, metadata)
    
    puts "✅ Build artifacts organized successfully"
    
    {
      build_directory: build_dir,
      metadata: metadata,
      apk_info: apk_info,
      aab_info: aab_info
    }
  end
  
  private
  
  def create_build_directory
    # Create environment-specific build directory structure
    base_dir = File.join(Dir.pwd, '..', '..', 'build', 'android')
    env_dir = File.join(base_dir, @environment)
    build_dir = File.join(env_dir, @build_time.strftime('%Y%m%d_%H%M%S'))
    
    FileUtils.mkdir_p(build_dir)
    
    # Create subdirectories
    %w[apk aab metadata logs].each do |subdir|
      FileUtils.mkdir_p(File.join(build_dir, subdir))
    end
    
    # Create symlink to latest build
    latest_link = File.join(env_dir, 'latest')
    if File.exist?(latest_link) || File.symlink?(latest_link)
      File.unlink(latest_link)
    end
    File.symlink(File.basename(build_dir), latest_link)
    
    puts "📁 Created build directory: #{build_dir}"
    build_dir
  end
  
  def process_apk_files(build_dir)
    apk_info = []
    
    # Find APK files in Flutter build output
    flutter_build_dir = File.join(Dir.pwd, '..', '..', 'build', 'app', 'outputs', 'flutter-apk')
    
    if Dir.exist?(flutter_build_dir)
      Dir.glob(File.join(flutter_build_dir, '*.apk')).each do |apk_path|
        next unless File.exist?(apk_path)
        
        # Generate environment-specific filename
        original_name = File.basename(apk_path)
        new_filename = generate_apk_filename(original_name)
        target_path = File.join(build_dir, 'apk', new_filename)
        
        # Copy APK with new name
        FileUtils.cp(apk_path, target_path)
        
        # Get APK information
        apk_data = {
          original_path: apk_path,
          target_path: target_path,
          filename: new_filename,
          size: File.size(target_path),
          checksum: calculate_checksum(target_path),
          build_type: detect_build_type(original_name)
        }
        
        apk_info << apk_data
        puts "📱 APK processed: #{new_filename}"
      end
    end
    
    apk_info
  end
  
  def process_aab_files(build_dir)
    aab_info = []
    
    # Find AAB files in Flutter build output
    flutter_build_dir = File.join(Dir.pwd, '..', '..', 'build', 'app', 'outputs', 'bundle')
    
    if Dir.exist?(flutter_build_dir)
      Dir.glob(File.join(flutter_build_dir, '**', '*.aab')).each do |aab_path|
        next unless File.exist?(aab_path)
        
        # Generate environment-specific filename
        original_name = File.basename(aab_path)
        new_filename = generate_aab_filename(original_name)
        target_path = File.join(build_dir, 'aab', new_filename)
        
        # Copy AAB with new name
        FileUtils.cp(aab_path, target_path)
        
        # Get AAB information
        aab_data = {
          original_path: aab_path,
          target_path: target_path,
          filename: new_filename,
          size: File.size(target_path),
          checksum: calculate_checksum(target_path),
          build_type: detect_build_type(original_name)
        }
        
        aab_info << aab_data
        puts "📦 AAB processed: #{new_filename}"
      end
    end
    
    aab_info
  end
  
  def generate_apk_filename(original_name)
    # Format: app-name-environment-buildtype-version-buildnumber-timestamp.apk
    app_name_clean = @app_name.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-')
    timestamp = @build_time.strftime('%Y%m%d-%H%M%S')
    
    build_type_suffix = @build_type || detect_build_type(original_name)
    
    "#{app_name_clean}-#{@environment}-#{build_type_suffix}-v#{@version_name}-#{@version_code}-#{timestamp}.apk"
  end
  
  def generate_aab_filename(original_name)
    # Format: app-name-environment-buildtype-version-buildnumber-timestamp.aab
    app_name_clean = @app_name.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-')
    timestamp = @build_time.strftime('%Y%m%d-%H%M%S')
    
    build_type_suffix = @build_type || detect_build_type(original_name)
    
    "#{app_name_clean}-#{@environment}-#{build_type_suffix}-v#{@version_name}-#{@version_code}-#{timestamp}.aab"
  end
  
  def detect_build_type(filename)
    return 'debug' if filename.include?('debug')
    return 'release' if filename.include?('release')
    @build_type || 'release'
  end
  
  def generate_build_metadata(apk_info, aab_info)
    {
      build_info: {
        environment: @environment,
        app_name: @app_name,
        bundle_id: @config['app']['bundle_id'],
        version_name: @version_name,
        version_code: @version_code,
        build_type: @build_type,
        build_time: @build_time.iso8601,
        build_timestamp: @build_time.to_i
      },
      configuration: {
        api_base_url: @config['network']['api_base_url'],
        websocket_url: @config['network']['websocket_url'],
        flavor: @config['build']['flavor'],
        obfuscate: @config['build']['obfuscate'],
        shrink_resources: @config['build']['shrink_resources']
      },
      artifacts: {
        apk_files: apk_info.map { |apk| 
          {
            filename: apk[:filename],
            size: apk[:size],
            size_human: format_file_size(apk[:size]),
            checksum: apk[:checksum],
            build_type: apk[:build_type]
          }
        },
        aab_files: aab_info.map { |aab| 
          {
            filename: aab[:filename],
            size: aab[:size],
            size_human: format_file_size(aab[:size]),
            checksum: aab[:checksum],
            build_type: aab[:build_type]
          }
        }
      },
      git_info: get_git_info,
      system_info: get_system_info
    }
  end
  
  def create_build_info_file(build_dir, metadata)
    # Create detailed build info JSON
    build_info_path = File.join(build_dir, 'metadata', 'build-info.json')
    File.write(build_info_path, JSON.pretty_generate(metadata))
    
    # Create simplified build info for compatibility
    simple_info = {
      environment: metadata[:build_info][:environment],
      app_name: metadata[:build_info][:app_name],
      bundle_id: metadata[:build_info][:bundle_id],
      version_name: metadata[:build_info][:version_name],
      version_code: metadata[:build_info][:version_code],
      build_type: metadata[:build_info][:build_type],
      build_time: metadata[:build_info][:build_time],
      api_base_url: metadata[:configuration][:api_base_url],
      websocket_url: metadata[:configuration][:websocket_url]
    }
    
    simple_info_path = File.join(build_dir, 'build-info.json')
    File.write(simple_info_path, JSON.pretty_generate(simple_info))
    
    puts "📋 Build metadata created"
  end
  
  def generate_checksums(build_dir)
    checksum_file = File.join(build_dir, 'metadata', 'checksums.txt')
    
    File.open(checksum_file, 'w') do |f|
      f.puts "# Build Artifact Checksums"
      f.puts "# Generated at: #{@build_time.iso8601}"
      f.puts "# Environment: #{@environment}"
      f.puts ""
      
      # Generate checksums for all files in apk and aab directories
      %w[apk aab].each do |subdir|
        dir_path = File.join(build_dir, subdir)
        next unless Dir.exist?(dir_path)
        
        Dir.glob(File.join(dir_path, '*')).each do |file_path|
          next unless File.file?(file_path)
          
          filename = File.basename(file_path)
          checksum = calculate_checksum(file_path)
          f.puts "#{checksum}  #{subdir}/#{filename}"
        end
      end
    end
    
    puts "🔐 Checksums generated"
  end
  
  def validate_artifacts(build_dir, metadata)
    puts "🔍 Validating build artifacts..."
    
    errors = []
    
    # Validate APK files exist and match metadata
    metadata[:artifacts][:apk_files].each do |apk_info|
      apk_path = File.join(build_dir, 'apk', apk_info[:filename])
      
      unless File.exist?(apk_path)
        errors << "APK file missing: #{apk_info[:filename]}"
        next
      end
      
      # Validate file size
      actual_size = File.size(apk_path)
      if actual_size != apk_info[:size]
        errors << "APK size mismatch for #{apk_info[:filename]}: expected #{apk_info[:size]}, got #{actual_size}"
      end
      
      # Validate checksum
      actual_checksum = calculate_checksum(apk_path)
      if actual_checksum != apk_info[:checksum]
        errors << "APK checksum mismatch for #{apk_info[:filename]}"
      end
    end
    
    # Validate AAB files exist and match metadata
    metadata[:artifacts][:aab_files].each do |aab_info|
      aab_path = File.join(build_dir, 'aab', aab_info[:filename])
      
      unless File.exist?(aab_path)
        errors << "AAB file missing: #{aab_info[:filename]}"
        next
      end
      
      # Validate file size
      actual_size = File.size(aab_path)
      if actual_size != aab_info[:size]
        errors << "AAB size mismatch for #{aab_info[:filename]}: expected #{aab_info[:size]}, got #{actual_size}"
      end
      
      # Validate checksum
      actual_checksum = calculate_checksum(aab_path)
      if actual_checksum != aab_info[:checksum]
        errors << "AAB checksum mismatch for #{aab_info[:filename]}"
      end
    end
    
    # Validate required files exist
    required_files = [
      'build-info.json',
      'metadata/build-info.json',
      'metadata/checksums.txt'
    ]
    
    required_files.each do |file|
      file_path = File.join(build_dir, file)
      unless File.exist?(file_path)
        errors << "Required file missing: #{file}"
      end
    end
    
    if errors.any?
      puts "❌ Artifact validation failed:"
      errors.each { |error| puts "  - #{error}" }
      raise "Artifact validation failed with #{errors.count} errors"
    else
      puts "✅ All artifacts validated successfully"
    end
  end
  
  def calculate_checksum(file_path)
    Digest::SHA256.file(file_path).hexdigest
  end
  
  def format_file_size(size)
    units = %w[B KB MB GB]
    unit_index = 0
    size_float = size.to_f
    
    while size_float >= 1024 && unit_index < units.length - 1
      size_float /= 1024
      unit_index += 1
    end
    
    "#{size_float.round(2)} #{units[unit_index]}"
  end
  
  def get_git_info
    begin
      {
        commit_hash: `git rev-parse HEAD`.strip,
        commit_short: `git rev-parse --short HEAD`.strip,
        branch: `git rev-parse --abbrev-ref HEAD`.strip,
        commit_message: `git log -1 --pretty=%B`.strip,
        commit_author: `git log -1 --pretty=%an`.strip,
        commit_date: `git log -1 --pretty=%ci`.strip,
        is_dirty: !`git status --porcelain`.strip.empty?
      }
    rescue => e
      puts "Failed to get git info: #{e.message}"
      {
        commit_hash: 'unknown',
        commit_short: 'unknown',
        branch: 'unknown',
        commit_message: 'unknown',
        commit_author: 'unknown',
        commit_date: 'unknown',
        is_dirty: false
      }
    end
  end
  
  def get_system_info
    fastlane_version = begin
      require 'fastlane'
      Fastlane::VERSION
    rescue LoadError
      'unknown'
    end
    
    {
      platform: RUBY_PLATFORM,
      ruby_version: RUBY_VERSION,
      fastlane_version: fastlane_version,
      build_machine: ENV['USER'] || ENV['USERNAME'] || 'unknown',
      build_os: RbConfig::CONFIG['host_os'],
      build_arch: RbConfig::CONFIG['host_cpu']
    }
  end
  
  # Class methods for utility functions
  
  def self.cleanup_old_builds(environment, keep_days = 30)
    puts "🧹 Cleaning up old builds for #{environment}"
    
    base_dir = File.join(Dir.pwd, '..', '..', 'build', 'android', environment)
    return unless Dir.exist?(base_dir)
    
    cutoff_time = Time.now - (keep_days * 24 * 60 * 60)
    removed_count = 0
    
    Dir.glob(File.join(base_dir, '*')).each do |build_dir|
      next unless File.directory?(build_dir)
      next if File.basename(build_dir) == 'latest' # Skip symlink
      
      # Parse timestamp from directory name (YYYYMMDD_HHMMSS)
      dir_name = File.basename(build_dir)
      next unless dir_name.match?(/^\d{8}_\d{6}$/)
      
      begin
        build_time = Time.strptime(dir_name, '%Y%m%d_%H%M%S')
        if build_time < cutoff_time
          FileUtils.rm_rf(build_dir)
          removed_count += 1
          puts "🗑️  Removed old build: #{dir_name}"
        end
      rescue => e
        puts "Failed to parse build time for #{dir_name}: #{e.message}"
      end
    end
    
    puts "✅ Cleaned up #{removed_count} old builds"
  end
  
  def self.list_builds(environment, limit = 10)
    puts "📋 Recent builds for #{environment}"
    
    base_dir = File.join(Dir.pwd, '..', '..', 'build', 'android', environment)
    unless Dir.exist?(base_dir)
      puts "No builds found for #{environment}"
      return
    end
    
    builds = Dir.glob(File.join(base_dir, '*'))
                .select { |path| File.directory?(path) && File.basename(path) != 'latest' }
                .sort_by { |path| File.basename(path) }
                .reverse
                .take(limit)
    
    if builds.empty?
      puts "No builds found for #{environment}"
      return
    end
    
    builds.each do |build_dir|
      dir_name = File.basename(build_dir)
      build_info_path = File.join(build_dir, 'build-info.json')
      
      if File.exist?(build_info_path)
        begin
          build_info = JSON.parse(File.read(build_info_path))
          version = "#{build_info['version_name']} (#{build_info['version_code']})"
          build_type = build_info['build_type']
          puts "📦 #{dir_name} - v#{version} (#{build_type})"
        rescue => e
          puts "📦 #{dir_name} - (info unavailable)"
        end
      else
        puts "📦 #{dir_name} - (no build info)"
      end
    end
  end
  
  def self.get_latest_build_info(environment)
    latest_dir = File.join(Dir.pwd, '..', '..', 'build', 'android', environment, 'latest')
    return nil unless File.exist?(latest_dir) && File.symlink?(latest_dir)
    
    build_info_path = File.join(latest_dir, 'build-info.json')
    return nil unless File.exist?(build_info_path)
    
    begin
      JSON.parse(File.read(build_info_path))
    rescue => e
      puts "Failed to read latest build info: #{e.message}"
      nil
    end
  end
end