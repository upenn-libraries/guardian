require 'rspec'

describe 'ChunkSizer' do
  ONE_KB   = 1024
  ONE_MB   = 1024 ** 2
  FOUR_MB  = ONE_MB * 4
  FIVE_MB  = ONE_MB * 5
  EIGHT_MB = ONE_MB * 8
  ONE_GB   = 1024 ** 3
  FOUR_GB  = ONE_GB * 4


  MAX_ARCHIVE_FOR_MINIMUM_CHUNK = FOUR_MB * 10000
  MIN_ARCHIVE_FOR_CHUNK_INCREMENT = MAX_ARCHIVE_FOR_MINIMUM_CHUNK + 1
  MAX_ARCHIVE_SIZE = (1024 ** 3 * 4 * 10000) - ONE_MB
  OVER_MAX_ARCHIVE_SIZE = MAX_ARCHIVE_SIZE + 1

  it 'should return a minimum chunk size of 4MB' do
    expect(ChunkSizer.calculate(ONE_KB)).to eq FOUR_MB
  end

  it 'should return a chunk size' do
    expect(ChunkSizer.calculate(FIVE_MB)).to eq FOUR_MB
  end

  it 'should return minimum chunk size when archive is 10,000 * 4MB' do
    expect(ChunkSizer.calculate(MAX_ARCHIVE_FOR_MINIMUM_CHUNK)).to eq FOUR_MB
  end

  it 'should increment chunk size' do
    expect(ChunkSizer.calculate(MIN_ARCHIVE_FOR_CHUNK_INCREMENT)).to eq EIGHT_MB
  end

  it 'should return max chunk size (4GB) for max archive size' do
    expect(ChunkSizer.calculate(MAX_ARCHIVE_SIZE)).to eq FOUR_GB
  end

  it 'should should raise an exception when the archive is too large' do
    expect {
      ChunkSizer.calculate(OVER_MAX_ARCHIVE_SIZE)
    }.to raise_error StandardError
  end

end
