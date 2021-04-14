# frozen_string_literal: true

module FileHelper
  def duplicate_fixture_with_new_ext(from_ext, to_ext)
    original_file = fixtures_root.join("data.#{from_ext}")
    test_file = fixtures_root.join("test-data.#{to_ext}")
    FileUtils.cp(original_file, test_file)

    test_file
  end
end
