# frozen_string_literal: true

module PathHelper
  def spec_root
    Pathname.new(File.dirname(__FILE__)).join("..")
  end

  def fixtures_root
    spec_root.join("fixtures")
  end
end
