# frozen_string_literal: true

RSpec.describe(EYAML::Rails::Railtie) do
  include EncryptionHelper
  include FileHelper
  include RailsHelper
  include FakeFS::SpecHelpers

  subject { described_class.instance }

  let(:secrets) { secrets_class.new }

  before(:each) do
    FakeFS::FileSystem.clone(fixtures_root)

    supported_extensions.each do |ext|
      FakeFS::FileUtils.copy_file(
        fixtures_root.join("data.#{ext}"),
        config_root.join("secrets.env.#{ext}")
      )

      FakeFS::FileUtils.copy_file(
        fixtures_root.join("data.#{ext}"),
        config_root.join("secrets.#{ext}")
      )
    end
  end

  it "should be a Railtie" do
    is_expected.to(be_a(::Rails::Railtie))
  end

  context "before configuration" do
    before do
      allow_rails.to(receive(:root).and_return(fixtures_root))
      allow_rails.to(receive_message_chain("application.secrets").and_return(secrets))
    end

    it "merges secrets into application secrets" do
      run_load_hooks
      expect(secrets).to(include(:secret))
    end

    it "decrypts data before merging" do
      run_load_hooks
      expect(secrets).to(include(secret: "password"))
    end

    it "uses $EJSON_PRIVATE_KEY instead of checking locally if it's set" do
      File.delete(public_key_path)
      allow(ENV).to receive(:[]).with("EJSON_PRIVATE_KEY").and_return(private_key)

      run_load_hooks
      expect(secrets).to(include(secret: "password"))
    end

    describe "prioritizes 'secrets' with extension" do
      it "eyaml" do
        remove_all_secrets_that_dont_end_with(".eyaml")
        run_load_hooks
        expect(secrets).to(include(_extension: "eyaml"))
      end

      it "eyml" do
        remove_all_secrets_that_dont_end_with(".eyml")
        run_load_hooks
        expect(secrets).to(include(_extension: "eyml"))
      end

      it "ejson" do
        remove_all_secrets_that_dont_end_with(".ejson")
        run_load_hooks
        expect(secrets).to(include(_extension: "ejson"))
      end
    end

    context "without secrets" do
      before { remove_secrets_files }

      describe "falls back to 'secrets.env' with extension" do
        before { allow_rails.to(receive(:env).and_return(:env)) }

        it "eyaml" do
          remove_all_secrets_that_dont_end_with(".eyaml")
          run_load_hooks
          expect(secrets).to(include(_extension: "eyaml"))
        end

        it "eyml" do
          remove_all_secrets_that_dont_end_with(".eyml")

          run_load_hooks
          expect(secrets).to(include(_extension: "eyml"))
        end

        it "ejson" do
          remove_all_secrets_that_dont_end_with(".ejson")
          run_load_hooks
          expect(secrets).to(include(_extension: "ejson"))
        end
      end

      it "does not load anything when Rails.env doesn't match" do
        expect(Rails).to(receive(:env).and_return(:production).at_least(:once))
        run_load_hooks
        expect(secrets).to(be_empty)
      end
    end

    context "without any eyaml" do
      before do
        remove_secrets_files
        remove_environment_secrets_files
      end

      it "does not load anything" do
        expect(Rails).to(receive(:env).and_return(:production).at_least(:once))
        run_load_hooks
        expect(secrets).to(be_empty)
      end
    end
  end
end
