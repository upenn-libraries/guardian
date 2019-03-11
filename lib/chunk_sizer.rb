##
# Following Amazon's {specifications}[https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html#qfacts],
# determine the correct chunk size for a multipart transfer:
#
# Maximum archive size:: 10,000 x 4 GB
# Maximum number of parts per upload:: 10,000
# Part size:: 1 MB to 4 GB, last part can be < 1 MB. You specify the size value
#             in bytes.
#             The part size must be a megabyte (1024 KB) multiplied by a power
#             of 2. For example, 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB),
#             8388608 (8 MB).
module ChunkSizer
  extend self

  ONE_MB               = 1024 ** 2

  ##
  # Begin with a chunk size of 4MB.
  INITIAL_CHUNK_SIZE   = ONE_MB * 4
  ONE_GB               = ONE_MB * 1024

  ##
  # The maximum number of chunks allowed is 10,000.
  MAX_CHUNK_COUNT      = 10000

  ##
  # The maximum allowed chunk size is 4GB.
  MAX_CHUNK_SIZE       = 4 * ONE_GB

  ##
  # The maximum size for an archive is 4GB x 10,000. We subtract 1MB to allow
  # for overhead; so, (4GB x 10,000) - 1MB.
  MAXIMUM_ARCHIVE_SIZE = (MAX_CHUNK_SIZE * 10000) - ONE_MB

  ##
  # Determine the appropriate ++multipart_chunk_size++ for the archive at
  # ++file_path++ following the part size requirements for Glacier
  # (https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html).
  #
  # Begin with a 4MB chunk size, doubling the value until the chunk size
  # multiplied by 10,000 is greater than size of the archive.
  #
  # Raise an exception if archive size is greater than ++MAXIMUM_ARCHIVE_SIZE++
  # or if the chunk size grows larger than ++MAX_CHUNK_SIZE++.
  #
  # @param [Integer] archive_size the size of the archive in bytes
  # @return [Integer] the chunk size in bytes
  # @raise [StandardError] if the size of ++file_path++ is greater than
  #                         ++MAXIMUM_ARCHIVE_SIZE++
  # @raise [RuntimeError] if the chunk size grows larger than ++MAX_CHUNK_SIZE++
  def calculate(archive_size)
    if archive_size > MAXIMUM_ARCHIVE_SIZE
      raise StandardError, "Archive too large: '#{file_path}' (size=#{archive_size}; maximum=#{MAXIMUM_ARCHIVE_SIZE})"
    end

    chunk_size = INITIAL_CHUNK_SIZE
    until chunk_size * MAX_CHUNK_COUNT >= archive_size
      chunk_size *= 2

      # Prevent an infinite loop. This is doubly cautious: if `archive_size` is
      # less than or equal to `MAXIMUM_ARCHIVE_SIZE`, then by definition the
      # chunk size has to be less than or equal to the MAX_CHUNK_SIZE.
      if chunk_size > MAX_CHUNK_SIZE
        raise "Chunk size too large: #{chunk_size} (max allowed: #{MAX_CHUNK_SIZE}"
      end
    end

    return chunk_size
  end
end
