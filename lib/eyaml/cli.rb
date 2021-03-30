class EYAML
  class CLI < Thor
    class_option :keydir, aliases: "-k", type: :string, default: ENV["EJSON_KEYDIR"] || EYAML::DEFAULT_KEYDIR, desc: "Directory containing EYAML keys"

    method_option :json, type: :boolean, aliases: "-j", desc: "output will be formatted as JSON", default: false
    desc "encrypt", "(Re-)encrypt one or more EYAML files"
    def encrypt(*files)
      files.each do |file|
        file_path = Pathname.new(file)
        next unless file_path.exist?

        bytes_written = EYAML.encrypt_file_in_place(
          file_path,
          keydir: options.fetch(:keydir),
          output_format: (options.fetch(:json) ? :json : :yaml)
        )

        puts "Wrote #{bytes_written} bytes to #{file_path}."
      end
    end

    method_option :output, type: :string, desc: "print output to the provided file, rather than stdout", aliases: "-o"
    method_option :json, type: :boolean, aliases: "-j", desc: "output will be formatted as JSON", default: false
    method_option :"key-from-stdin", type: :boolean, desc: "read the private key from STDIN", default: false
    desc "decrypt", "Decrypt an EYAML file"
    def decrypt(file)
      key_options = if options.fetch(:"key-from-stdin")
        # Read key from STDIN
        {private_key: ARGF}
      else
        {keydir: options.fetch(:keydir)}
      end

      plaindata = EYAML.decrypt_file(file, **key_options)
      eyaml = if options.fetch(:json)
        JSON.pretty_generate(plaindata)
      else
        EYAML::Util.pretty_yaml(plaindata)
      end

      if options.has_key?(:output)
        output_file = Pathname.new(options.fetch(:output))
        File.write(output_file, eyaml)
        return
      end

      puts eyaml
    end

    method_option :write, type: :boolean, aliases: "-w", desc: "rather than printing both keys, print the public and write the private into the keydir", default: false
    desc "keygen", "Generate a new EYAML keypair"
    def keygen
      public_key, private_key = EYAML.generate_keypair

      if options.fetch(:write)
        public_key_path = File.expand_path(public_key, options.fetch(:keydir))

        File.write(public_key_path, private_key)
        puts "Public Key: #{public_key}"
      else
        puts "Public Key: #{public_key}"
        puts "Private Key: #{private_key}"
      end
    end

    map e: :encrypt
    map d: :decrypt
    map g: :keygen

    def self.exit_on_failure?
      true
    end
  end
end
