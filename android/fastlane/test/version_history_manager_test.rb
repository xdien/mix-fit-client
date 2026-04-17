require 'minitest/autorun'
require 'minitest/spec'
require 'fileutils'
require 'tmpdir'
require 'json'
require 'time'
require_relative '../version_history_manager'

describe VersionHistoryManager do
  before do
    # Create a temporary directory for testing
    @temp_dir = Dir.mktmpdir('version_history_test')
    @history_manager = VersionHistoryManager.new(@temp_dir)
    
    # Mock git commands
    @history_manager.define_singleton_method(:get_current_commit_hash) { 'abc123def456' }
    @history_manager.define_singleton_method(:get_current_branch) { 'main' }
  end

  after do
    # Cleanup
    FileUtils.rm_rf(@temp_dir)
  end

  describe '#record_version_change' do
    it 'should record version changes correctly' do
      old_version = { version_name: '1.0.0', build_number: 1 }
      new_version = { version_name: '1.0.0', build_number: 2 }
      
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
      
      @history_manager.record_version_change(old_version, new_version, 'build_increment', 'development')
      
      history = @history_manager.get_history
      _(history.length).must_equal 1
      
      change = history.first
      _(change['old_version']).must_equal old_version
      _(change['new_version']).must_equal new_version
      _(change['change_type']).must_equal 'build_increment'
      _(change['environment']).must_equal 'development'
      _(change['commit_hash']).must_equal 'abc123def456'
      _(change['branch']).must_equal 'main'
    end

    it 'should handle multiple version changes' do
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
      
      # Record multiple changes
      changes = [
        [{ version_name: '1.0.0', build_number: 1 }, { version_name: '1.0.0', build_number: 2 }, 'build_increment'],
        [{ version_name: '1.0.0', build_number: 2 }, { version_name: '1.0.1', build_number: 2 }, 'patch'],
        [{ version_name: '1.0.1', build_number: 2 }, { version_name: '1.1.0', build_number: 2 }, 'minor']
      ]
      
      changes.each do |old_ver, new_ver, change_type|
        @history_manager.record_version_change(old_ver, new_ver, change_type, 'development')
      end
      
      history = @history_manager.get_history
      _(history.length).must_equal 3
      
      # Check that changes are in chronological order
      _(history[0]['change_type']).must_equal 'build_increment'
      _(history[1]['change_type']).must_equal 'patch'
      _(history[2]['change_type']).must_equal 'minor'
    end
  end

  describe '#get_history' do
    before do
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
      
      # Add some test data
      5.times do |i|
        old_ver = { version_name: '1.0.0', build_number: i + 1 }
        new_ver = { version_name: '1.0.0', build_number: i + 2 }
        @history_manager.record_version_change(old_ver, new_ver, 'build_increment', 'development')
      end
    end

    it 'should return all history when no limit specified' do
      history = @history_manager.get_history
      _(history.length).must_equal 5
    end

    it 'should respect limit parameter' do
      history = @history_manager.get_history(3)
      _(history.length).must_equal 3
      
      # Should return the last 3 entries
      _(history.last['new_version']['build_number']).must_equal 6
    end

    it 'should return empty array when no history exists' do
      fresh_manager = VersionHistoryManager.new(Dir.mktmpdir)
      history = fresh_manager.get_history
      _(history).must_be_empty
    end
  end

  describe '#get_statistics' do
    before do
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
      
      # Add diverse test data
      test_changes = [
        ['build_increment', 3],
        ['patch', 2],
        ['minor', 1],
        ['major', 1],
        ['manual', 1]
      ]
      
      test_changes.each do |change_type, count|
        count.times do |i|
          old_ver = { version_name: '1.0.0', build_number: 1 }
          new_ver = { version_name: '1.0.0', build_number: 2 }
          @history_manager.record_version_change(old_ver, new_ver, change_type, 'development')
        end
      end
    end

    it 'should calculate statistics correctly' do
      stats = @history_manager.get_statistics
      
      _(stats['total_changes']).must_equal 8
      _(stats['build_increments']).must_equal 3
      _(stats['patch_releases']).must_equal 2
      _(stats['minor_releases']).must_equal 1
      _(stats['major_releases']).must_equal 1
      _(stats['manual_updates']).must_equal 1
      
      _(stats['first_recorded']).wont_be_nil
      _(stats['last_updated']).wont_be_nil
    end

    it 'should handle empty history' do
      fresh_manager = VersionHistoryManager.new(Dir.mktmpdir)
      stats = fresh_manager.get_statistics
      
      _(stats['total_changes']).must_equal 0
      _(stats['build_increments']).must_equal 0
      _(stats['first_recorded']).must_be_nil
    end
  end

  describe '#generate_changelog' do
    before do
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
      
      # Add test data with different versions
      changes = [
        [{ version_name: '1.0.0', build_number: 1 }, { version_name: '1.0.1', build_number: 1 }, 'patch'],
        [{ version_name: '1.0.1', build_number: 1 }, { version_name: '1.0.1', build_number: 2 }, 'build_increment'],
        [{ version_name: '1.0.1', build_number: 2 }, { version_name: '1.1.0', build_number: 1 }, 'minor']
      ]
      
      changes.each do |old_ver, new_ver, change_type|
        @history_manager.record_version_change(old_ver, new_ver, change_type, 'development')
      end
    end

    it 'should generate changelog with all versions' do
      changelog = @history_manager.generate_changelog
      
      _(changelog).must_include '# Changelog'
      _(changelog).must_include '## Version 1.0.1'
      _(changelog).must_include '## Version 1.1.0'
      _(changelog).must_include 'Patch release'
      _(changelog).must_include 'Build_increment release'
      _(changelog).must_include 'Minor release'
    end

    it 'should generate changelog since specific version' do
      changelog = @history_manager.generate_changelog('1.0.1')
      
      _(changelog).must_include '# Changelog'
      _(changelog).must_include '## Version 1.1.0'
      _(changelog).wont_include '## Version 1.0.1'
    end
  end

  describe '#cleanup_history' do
    before do
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
    end

    it 'should remove old entries' do
      # Create entries with different timestamps
      old_time = Time.now - (100 * 24 * 60 * 60) # 100 days ago
      recent_time = Time.now - (10 * 24 * 60 * 60) # 10 days ago
      
      # Manually create history with old timestamps
      history = {
        'version' => '1.0',
        'created' => Time.now.iso8601,
        'last_updated' => Time.now.iso8601,
        'changes' => [
          {
            'timestamp' => old_time.iso8601,
            'old_version' => { 'version_name' => '1.0.0', 'build_number' => 1 },
            'new_version' => { 'version_name' => '1.0.0', 'build_number' => 2 },
            'change_type' => 'build_increment',
            'environment' => 'development'
          },
          {
            'timestamp' => recent_time.iso8601,
            'old_version' => { 'version_name' => '1.0.0', 'build_number' => 2 },
            'new_version' => { 'version_name' => '1.0.1', 'build_number' => 2 },
            'change_type' => 'patch',
            'environment' => 'development'
          }
        ]
      }
      
      # Save the history manually
      history_file = File.join(@temp_dir, 'version_history.json')
      File.write(history_file, JSON.pretty_generate(history))
      
      # Clean up entries older than 90 days
      removed_count = @history_manager.cleanup_history(90)
      
      _(removed_count).must_equal 1
      
      # Verify only recent entry remains
      remaining_history = @history_manager.get_history
      _(remaining_history.length).must_equal 1
      _(remaining_history.first['change_type']).must_equal 'patch'
    end

    it 'should not remove recent entries' do
      # Add recent entry
      old_ver = { version_name: '1.0.0', build_number: 1 }
      new_ver = { version_name: '1.0.0', build_number: 2 }
      @history_manager.record_version_change(old_ver, new_ver, 'build_increment', 'development')
      
      removed_count = @history_manager.cleanup_history(90)
      
      _(removed_count).must_equal 0
      
      # Verify entry still exists
      history = @history_manager.get_history
      _(history.length).must_equal 1
    end
  end

  describe '#export_history' do
    before do
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(
          success: proc { |msg| puts "SUCCESS: #{msg}" },
          message: proc { |msg| puts "MESSAGE: #{msg}" }
        )
      end
      
      # Add test data
      old_ver = { version_name: '1.0.0', build_number: 1 }
      new_ver = { version_name: '1.0.1', build_number: 1 }
      @history_manager.record_version_change(old_ver, new_ver, 'patch', 'development')
    end

    it 'should export to JSON format' do
      output_file = @history_manager.export_history('json')
      
      _(File.exist?(output_file)).must_equal true
      _(output_file).must_match /\.json$/
      
      # Verify content
      content = JSON.parse(File.read(output_file))
      _(content['changes']).wont_be_empty
      _(content['changes'].first['change_type']).must_equal 'patch'
    end

    it 'should export to CSV format' do
      output_file = @history_manager.export_history('csv')
      
      _(File.exist?(output_file)).must_equal true
      _(output_file).must_match /\.csv$/
      
      # Verify content
      content = File.read(output_file)
      _(content).must_include 'Timestamp,Old Version,New Version'
      _(content).must_include 'patch'
    end

    it 'should export to Markdown format' do
      output_file = @history_manager.export_history('markdown')
      
      _(File.exist?(output_file)).must_equal true
      _(output_file).must_match /\.md$/
      
      # Verify content
      content = File.read(output_file)
      _(content).must_include '# Changelog'
      _(content).must_include '## Version 1.0.1'
    end

    it 'should raise error for unsupported format' do
      _(proc { @history_manager.export_history('xml') }).must_raise ArgumentError
    end
  end

  describe 'file handling' do
    it 'should create history file if it does not exist' do
      history_file = File.join(@temp_dir, 'version_history.json')
      _(File.exist?(history_file)).must_equal false
      
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(message: proc { |msg| puts msg })
      end
      
      # Record a change (this should create the file)
      old_ver = { version_name: '1.0.0', build_number: 1 }
      new_ver = { version_name: '1.0.0', build_number: 2 }
      @history_manager.record_version_change(old_ver, new_ver, 'build_increment', 'development')
      
      _(File.exist?(history_file)).must_equal true
    end

    it 'should handle corrupted history file' do
      # Create corrupted history file
      history_file = File.join(@temp_dir, 'version_history.json')
      File.write(history_file, 'invalid json content {')
      
      # Mock UI
      @history_manager.define_singleton_method(:UI) do
        OpenStruct.new(
          error: proc { |msg| puts "ERROR: #{msg}" },
          message: proc { |msg| puts "MESSAGE: #{msg}" }
        )
      end
      
      # Should create new history instead of crashing
      old_ver = { version_name: '1.0.0', build_number: 1 }
      new_ver = { version_name: '1.0.0', build_number: 2 }
      @history_manager.record_version_change(old_ver, new_ver, 'build_increment', 'development')
      
      # Should have created new valid history
      history = @history_manager.get_history
      _(history.length).must_equal 1
    end
  end
end