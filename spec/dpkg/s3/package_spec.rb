# frozen_string_literal: true

require File.expand_path('../../spec_helper', __dir__)
require 'dpkg/s3/package'

EXPECTED_DESCRIPTION = 'A platform for community discussion. Free, open, simple.'\
"\nThe description can have a continuation line.\n\nAnd blank lines."\
"\n\nIf it wants to."

describe Dpkg::S3::Package do
  describe '.parse_string' do
    it 'creates a Package object with the right attributes' do
      package = Dpkg::S3::Package.parse_string(File.read(fixture('Packages')))
      assert_equal package.version, '0.9.8.3'
      assert_nil package.epoch
      assert_equal package.iteration, '1396474125.12e4179.wheezy'
      assert_equal package.full_version, '0.9.8.3-1396474125.12e4179.wheezy'
      assert_equal package.description, EXPECTED_DESCRIPTION
    end
  end

  describe '#full_version' do
    it 'returns nil if no version, epoch, iteration' do
      package = create_package
      assert_nil package.full_version
    end

    it 'returns only the version if no epoch and no iteration' do
      package = create_package version: '0.9.8'
      assert_equal package.full_version, '0.9.8'
    end

    it 'returns epoch:version if epoch and version' do
      epoch = Time.now.to_i
      package = create_package version: '0.9.8', epoch: epoch
      assert_equal package.full_version, "#{epoch}:0.9.8"
    end

    it 'returns version-iteration if version and iteration' do
      package = create_package version: '0.9.8', iteration: '2'
      assert_equal package.full_version, '0.9.8-2'
    end

    it 'returns epoch:version-iteration if epoch and version and iteration' do
      epoch = Time.now.to_i
      package = create_package version: '0.9.8', iteration: '2', epoch: epoch
      assert_equal package.full_version, "#{epoch}:0.9.8-2"
    end
  end
end
