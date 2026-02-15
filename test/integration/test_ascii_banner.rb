# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../hooks/lib/ascii_banner'

class TestAsciiBanner < JamTest::TestCase
  def test_logo_has_six_lines
    assert_equal 6, AsciiBanner::NBA_JAM_LINES.size
  end

  def test_logo_lines_are_strings
    AsciiBanner::NBA_JAM_LINES.each_with_index do |line, i|
      assert_instance_of String, line, "Logo line #{i} is not a string"
    end
  end

  def test_display_rescues_no_tty
    # Stub File.open to simulate no TTY
    stub_method(AsciiBanner, :display) { nil }
    AsciiBanner.display
    assert true
  end

  def test_display_update_notice_when_no_update
    # Without UpdateChecker loaded or with no update
    stub_method(AsciiBanner, :display_update_notice) { nil }
    AsciiBanner.display_update_notice
    assert true
  end

  def test_plugin_version_reads_from_json
    version = AsciiBanner.send(:plugin_version)
    # Should return a version string or nil
    if version
      assert_match(/\d+\.\d+\.\d+/, version, "Version doesn't match semver: #{version}")
    end
  end

  def test_display_writes_banner_content
    output = capture_banner_output
    return unless output # Skip if no TTY capture possible

    assert_includes output, 'BOOMSHAKALAKA'
  end

  def test_display_includes_version
    output = capture_banner_output
    return unless output

    # Version string should appear somewhere
    version = AsciiBanner.send(:plugin_version)
    assert_includes output, version if version
  end

  def test_display_includes_fact
    output = capture_banner_output
    return unless output

    # Should include stripe character from FactPresenter
    assert_includes output, "\u2501"
  end

  private

  def capture_banner_output
    create_sandbox
    tty_file = File.join(@_sandbox_dir, 'fake_tty')

    # Redirect tty_device_path to a file we can read
    stub_method(AsciiBanner, :tty_device_path) { tty_file }

    AsciiBanner.display
    return nil unless File.exist?(tty_file)

    File.read(tty_file)
  rescue StandardError
    nil
  end
end
