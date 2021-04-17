# frozen_string_literal: true

require File.expand_path('../../spec_helper', __dir__)
require 'dpkg/s3/lock'
require 'minitest/mock'

describe Dpkg::S3::Lock do
  describe :locked? do
    it 'returns true if lock file exists' do
      Dpkg::S3::Utils.stub :s3_exists?, true do
        assert_equal Dpkg::S3::Lock.locked?('stable'), true
      end
    end
    it 'returns true if lock file exists' do
      Dpkg::S3::Utils.stub :s3_exists?, false do
        assert_equal Dpkg::S3::Lock.locked?('stable'), false
      end
    end
  end

  describe :lock do
    it 'creates a lock file' do
      s3_store_mock = MiniTest::Mock.new
      s3_store_mock.expect(:call, nil, 4.times.map { Object })

      s3_read_mock = MiniTest::Mock.new
      s3_read_mock.expect(:call, "foo@bar\nabcde", [String])

      lock_content_mock = MiniTest::Mock.new
      lock_content_mock.expect(:call, "foo@bar\nabcde")

      Dpkg::S3::Utils.stub :s3_store, s3_store_mock do
        Dpkg::S3::Utils.stub :s3_read, s3_read_mock do
          Dpkg::S3::Lock.stub :generate_lock_content, lock_content_mock do
            Dpkg::S3::Lock.lock('stable')
          end
        end
      end

      s3_read_mock.verify
      s3_store_mock.verify
      lock_content_mock.verify
    end
  end

  describe :unlock do
    it 'deletes the lock file' do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil, [String])
      Dpkg::S3::Utils.stub :s3_remove, mock do
        Dpkg::S3::Lock.unlock('stable')
      end
      mock.verify
    end
  end

  describe :current do
    before :each do
      mock = MiniTest::Mock.new
      mock.expect(:call, 'alex@localhost', [String])
      Dpkg::S3::Utils.stub :s3_read, mock do
        @lock = Dpkg::S3::Lock.current('stable')
      end
    end

    it 'returns a lock object' do
      _(@lock).must_be_instance_of Dpkg::S3::Lock
    end

    it 'holds the user who currently holds the lock' do
      _(@lock.user).must_equal 'alex'
    end

    it 'holds the hostname from where the lock was set' do
      _(@lock.host).must_equal 'localhost'
    end
  end
end
