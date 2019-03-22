require 'digest'

module Checksum
  extend self

  # 64KB block size
  DEFAULT_BLOCK_SIZE = 1<<16
  DEFAULT_MESSAGE_IO = STDERR

  ##
  # Validate the manifest at +path+, using +algorithm+. By default messages are
  # printed to +$stderr+. Alternate output may be provided via +message_io+.
  #
  # == Examples:
  #
  #     ManifestValidation::validate_manifest 'manifest.txt', 'sha256'
  #         test/stronghold_example.rb: OK
  #         test/test_push.rb: OK
  #         => true
  #
  #
  # Use {StringIO} to return the message as a string.
  #
  #     io = StringIO.new
  #         => #<StringIO:0x00007f877ad026a0>
  #     ManifestValidation::validate_manifest 'manifest.txt', 'sha256', message_io: io
  #         => true
  #     io.string
  #         => "test/stronghold_example.rb: OK\ntest/test_push.rb: OK\n"
  #
  #
  # @param path [String] path to the manifest
  # @param algorithm [String] checksum algorithm to use; valid values are
  #                           'sha1', 'sha256', 'sha384', 'sha512', 'md5'
  # @param blocksize [Long,Integer] blocksize for reading
  # @param message_io [IO] where to write messages
  # @return [Boolean] +true+ if all files pass; +false+ otherwise
  def validate_manifest path, algorithm, blocksize: DEFAULT_BLOCK_SIZE, message_io: DEFAULT_MESSAGE_IO
    passed = true
    IO.foreach path do |line|
      checksum = line.split.first
      path = line.chomp.split(/[ \t]+/, 2).last
      unless File.file? path
        message_io.puts "#{path}: FILE_NOT_FOUND" unless message_io.nil?
        passed = false
        next
      end

      if validate_file checksum, path, algorithm, blocksize: blocksize
        message_io.puts "#{path}: OK" unless message_io.nil?
      else
        message_io.puts "#{path}: FAIL" unless message_io.nil?
        passed = false
      end
    end
    passed
  end

  ##
  # Validate +file_or_io+ against +checksum+, using +algorithm+.
  #
  # @param checksum [String] hex format checksum to check against
  # @param file_or_io [String,IO] path to a file an IO instance
  # @param algorithm [String] checksum algorithm to use; valid values are
  #                           'sha1', 'sha256', 'sha384', 'sha512', 'md5'
  # @param blocksize [Long,Integer] blocksize for reading
  # @return [Boolean] +true+ file's checksum matches checksum param
  def validate_file checksum, file_or_io, algorithm, blocksize: DEFAULT_BLOCK_SIZE
    file_checksum = get_checksum file_or_io, algorithm, blocksize: blocksize

    checksum == file_checksum
  end

  ##
  # Get the checksum for +file_or_io+ using +algorithm+.
  #
  # @param file_or_io [String,IO] path to a file an IO instance
  # @param algorithm [String] checksum algorithm to use; valid values are
  #                           'sha1', 'sha256', 'sha384', 'sha512', 'md5'
  # @param blocksize [Long,Integer] blocksize for reading
  # @return [String] the file's digest in hex format
  def get_checksum file_or_io, algorithm, blocksize: DEFAULT_BLOCK_SIZE
    digest = digest_instance algorithm
    data = file_or_io.is_a?(IO)  ? file_or_io : File.open(file_or_io, 'rb')
    digest << data.read(blocksize) until data.eof?
    digest.hexdigest
  end

  ##
  # Get a new digest instance for +algorithm+.
  #
  # @param algorithm [String] checksum algorithm to use; valid values are
  #                           'sha1', 'sha256', 'sha384', 'sha512', 'md5'
  # @return [Digest] a new digest instance for +algorithm+
  def digest_instance algorithm
    case algorithm.to_s.strip.downcase
    when /\Asha-?1\z/
      Digest::SHA1.new
    when /\Asha-?256\z/
      Digest::SHA256.new
    when /\Asha-?512\z/
      Digest::SHA512.new
    when /\Asha-?384\z/
      Digest::SHA384.new
    when /\Amd-?5\z/
      Digest::MD5.new
    else
      raise ArgumentError, "Unknown digest type: #{algorithm}"
    end
  end

end
