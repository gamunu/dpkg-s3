# frozen_string_literal: true

require 'tempfile'
require 'socket'
require 'etc'
require 'securerandom'

# Dpkg is the root module for all storage modules including S3
module Dpkg
  # S3 storage module resposible of handling packages on S3 including upload, delete
  module S3
    # Lock is resposible of creating lock file on S3 to ensure when multiple instances of uploads will
    # not conflict with each other
    class Lock
      attr_accessor :user, :host

      def initialize
        @user = nil
        @host = nil
      end

      class << self
        def locked?(codename, component = nil, architecture = nil, cache_control = nil)
          Dpkg::S3::Utils.s3_exists?(lock_path(codename, component, architecture, cache_control))
        end

        def wait_for_lock(codename, component = nil, architecture = nil, cache_control = nil)
          max_attempts = 60
          wait = 10
          attempts = 0
          while locked?(codename, component, architecture, cache_control)
            attempts += 1
            throw "Unable to obtain a lock after #{max_attempts}, giving up." if attempts > max_attempts
            sleep(wait)
          end
        end

        def lock(codename, component = nil, architecture = nil, cache_control = nil)
          lockfile = Tempfile.new('lockfile')
          lock_content = generate_lock_content
          lockfile.write lock_content
          lockfile.close

          Dpkg::S3::Utils.s3_store(lockfile.path,
                                   lock_path(codename, component, architecture, cache_control),
                                   'text/plain',
                                   cache_control)

          return if lock_content == Dpkg::S3::Utils.s3_read(lock_path(codename, component, architecture, cache_control))

          throw 'Failed to acquire lock, was overwritten by another deb-s3 process'
        end

        def unlock(codename, component = nil, architecture = nil, cache_control = nil)
          Dpkg::S3::Utils.s3_remove(lock_path(codename, component, architecture, cache_control))
        end

        def current(codename, component = nil, architecture = nil, cache_control = nil)
          lock_content = Dpkg::S3::Utils.s3_read(lock_path(codename, component, architecture, cache_control))
          lock_content = lock_content.split.first.split('@')
          lock = Dpkg::S3::Lock.new
          lock.user = lock_content[0]
          lock.host = lock_content[1] if lock_content.size > 1
          lock
        end

        private

        def lock_path(codename, component = nil, architecture = nil, _cache_control = nil)
          "dists/#{codename}/#{component}/binary-#{architecture}/lockfile"
        end

        def generate_lock_content
          "#{Etc.getlogin}@#{Socket.gethostname}\n#{SecureRandom.hex}"
        end
      end
    end
  end
end
