module EncryptionHelper
  extend RSpec::SharedContext
  include FakeFS::SpecHelpers

  let(:encrypted_value_regex) { /\AEJ\[[\w:\/+=]+\]\z/ }
  let(:supported_extensions) { %w[eyaml eyml ejson] }

  let(:default_keydir) { "/opt/ejson/keys" }
  let(:test_keydir) { "/opt/some/other/keydir/" }
  let(:public_key) { "d1c7ba73c520445c5ba14984da8119f2f7b8df7bcdb3f37f5afe9613b118936a" }
  let(:private_key) { "e13c492e2076a70250f94bbc00b10a700b746356a7cf45b915aa43bc6867eba8" }
  let(:public_key_path) { File.join(default_keydir, public_key) }

  let(:data) {
    {
      "_public_key" => public_key,
      "secret" => "EJ[1:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]",
      "s3cr3t" => "p4ssw0rd",
      "_skip_me" => "not_secret",
      "_extension" => "ejson", # This is only the correct value for data.ejson
      "_dont_skip_me" => {
        "another_secret" => "ssshhh",
        "_underscored_secret" => "not encrypted"
      }
    }
  }

  before(:each) do
    FileUtils.mkdir_p(default_keydir)
    FileUtils.mkdir_p(test_keydir)
    File.write(public_key_path, private_key)

    supported_extensions.each do |ext|
      FakeFS::FileSystem.clone(fixtures_root.join("data.#{ext}"))
    end
  end
end
