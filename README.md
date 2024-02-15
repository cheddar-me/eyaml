# eyaml

`eyaml` is a tool for asymmetric encryption of YAML and JSON files. It's largely based on [`ejson`](https://github.com/Shopify/ejson) and backwards compatible with any `*.ejson` file.

Assymetric encryption is handled by [RubyCrypto/rbnacl](https://github.com/RubyCrypto/rbnacl/wiki) using a [sealed box](https://github.com/RubyCrypto/rbnacl/wiki/Public-Key-Encryption).

## Installation

To install `eyaml`, run:

```shell
gem install eyaml
```

Or alternatively, you can add it to your Gemfile:
```ruby
gem 'eyaml'
```

### Dependencies

`eyaml` depends on [libsodium](https://github.com/jedisct1/libsodium). At least `1.0.0` is required.

For MacOS users, libsodium is available via homebrew and can be installed with:
```shell
brew install libsodium
```

## Usage

`eyaml` requires that a file has a `_public_key` attribute that corresponds to the value generated by running `eyaml keygen`. Adding a plaintext value into the file and running `eyaml encrypt secrets.eyaml` (for a file called `secrets.eyaml`) will encrypt the value using the public key in the same file. To decrypt, ensure a private key is accessible and run `eyaml decrypt secrets.eyaml`

`eyaml` supports both JSON and YAML with the extensions `eyaml`, `eyml`, and `ejson`. It will using the extension to determine the format of its output.

### CLI

`eyaml` is primarily interacted through its CLI.

```
-> % eyaml help
Commands:
  eyaml decrypt         # Decrypt an EYAML file
  eyaml encrypt         # (Re-)encrypt one or more EYAML files
  eyaml help [COMMAND]  # Describe available commands or one specific command
  eyaml keygen          # Generate a new EYAML keypair

Options:
  -k, [--keydir=KEYDIR]  # Directory containing EYAML keys
```

#### `eyaml encrypt`

(Re-)encrypt one or more EYAML files. This is used whenever you add a new value to the config file.

```shell
-> % eyaml encrypt config/secrets.production.eyaml
Wrote 517 bytes to config/secrets.production.eyaml.
```


#### `eyaml decrypt`

Decrypts the provided EYAML file.

```shell
-> % eyaml decrypt config/secrets.production.eyaml
_public_key: d1c7ba73c520445c5ba14984da8119f2f7b8df7bcdb3f37f5afe9613b118936a
secret: password
```

#### `eyaml keygen`

Generates the keypair for the encryption flow to work. The public key must be placed into the file at `_public_key` like this:
e.g.
```shell
-> % cat config/credentials.development.eyaml
_public_key: a3dbdef9efd1e52a34588de56a6cf9b03bbc2aaf0edda145cfbd9a6370a0a849
my_secret: 85d1fca99d98c4e7b83b868f75f809e1e33346317b0c354b593cdcdc8793ad4e
```

The private key must be saved in the default key directory (`/opt/ejson/keys`) with the filename being the public key and the contents, the private key, a key directory you'll provide later, or just pass the `--write` flag for `eyaml` to handle it for you.

```shell
-> % eyaml keygen
Public Key: a3dbdef9efd1e52a34588de56a6cf9b03bbc2aaf0edda145cfbd9a6370a0a849
Private Key: b01592942ba10f152bcf7c6b6734f6392554c578ff24cebcc62f9e3da6fcf302

# Or by using the --write flag

-> % eyaml keygen --write
Public Key: a3dbdef9efd1e52a34588de56a6cf9b03bbc2aaf0edda145cfbd9a6370a0a849

-> % cat /opt/ejson/keys/a3dbdef9efd1e52a34588de56a6cf9b03bbc2aaf0edda145cfbd9a6370a0a849
b01592942ba10f152bcf7c6b6734f6392554c578ff24cebcc62f9e3da6fcf302
```

### Rails

`eyaml` comes with baked in Rails support. It will search for a secrets or credentials file in `config/`, decrypt, and load the first valid one it finds.
Credential files have priority over secrets before rails 7.2:
`credentials.{eyaml|eyml|ejson}` (e.g. `config/credentials.eyaml`) then `credentials.$env.{eyaml|eyml|ejson}` (e.g. `credentials.production.eyml`).
Then if no credentials are found it will look for a secrets file:
`secrets.{eyaml|eyml|ejson}` (e.g. `config/secrets.eyaml`) then `secrets.$env.{eyaml|eyml|ejson}` (e.g. `secrets.production.eyml`).

Note: From rails 7.2 onwards secrets are deprecated and eyaml will only look for credential files.

Instead of needing a private key locally, you can provide it to EYAML by setting `EJSON_PRIVATE_KEY` and it'll be automatically used for decrypting the secrets file.

### Apple M1 Support

If you're using the new Apple M1, you need to ensure that you're using a `ffi` that is working. We've temporarily been including a fork with a fix in any `Gemfile` where we've included `eyaml`:

```ruby
gem "ffi", github: "cheddar-me/ffi", branch: "apple-m1", submodules: true
```

## Development

To get started, make sure you have a working version of Ruby locally. Then clone the repo, and run `bin/setup` (this will install `libsodium` if you're on a Mac and setup bundler). Running `bundle exec rake` or `bundle exec rake spec` will run the test suite.

