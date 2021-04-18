# frozen_string_literal: true

require 'base64'
require 'digest/md5'
require 'erb'
require 'tmpdir'

# Dpkg is the root module for all storage modules including S3
module Dpkg
  # S3 storage module resposible of handling packages on S3 including upload, delete
  module S3
    # Utils contains functions will be used in Package and Release modules
    module Utils
      extend self

      attr_accessor :s3, :bucket, :access_policy, :signing_key, :gpg_options, :prefix, :encryption

      class SafeSystemError < RuntimeError; end

      class AlreadyExistsError < RuntimeError; end

      def safesystem(*args)
        success = system(*args)
        unless success
          raise SafeSystemError,
                "'system(#{args.inspect})' failed with error code: #{$CHILD_STATUS.exitstatus}"
        end

        success
      end

      def debianize_op(operator)
        # Operators in debian packaging are <<, <=, =, >= and >>
        # So any operator like < or > must be replaced
        { :< => '<<', :> => '>>' }[operator.to_sym] or operator
      end

      def template(path)
        template_file = File.join(File.dirname(__FILE__), 'templates', path)
        template_code = File.read(template_file)
        ERB.new(template_code, nil, '-')
      end

      def s3_path(path)
        File.join(*[Dpkg::S3::Utils.prefix, path].compact)
      end

      # from fog, Fog::AWS.escape
      def s3_escape(string)
        string.gsub(/([^a-zA-Z0-9_.\-~+]+)/) do
          "%#{Regexp.last_match(1).unpack('H2' * Regexp.last_match(1).bytesize).join('%').upcase}"
        end
      end

      def s3_exists?(path)
        Dpkg::S3::Utils.s3.head_object(
          bucket: Dpkg::S3::Utils.bucket,
          key: s3_path(path)
        )
      rescue Aws::S3::Errors::NotFound
        false
      end

      def s3_read(path)
        Dpkg::S3::Utils.s3.get_object(
          bucket: Dpkg::S3::Utils.bucket,
          key: s3_path(path)
        )[:body].read
      rescue Aws::S3::Errors::NoSuchKey
        false
      end

      def s3_store(path, filename = nil, content_type = 'application/x-debian-package',
                   cache_control = nil, fail_if_exists: false)
        filename ||= File.basename(path)
        obj = s3_exists?(filename)

        file_md5 = Digest::MD5.file(path)

        # check if the object already exists
        if obj != false
          return if (file_md5.to_s == obj[:etag].gsub('"', '')) || (file_md5.to_s == obj[:metadata]['md5'])
          raise AlreadyExistsError, "file #{filename} already exists with different contents" if fail_if_exists
        end

        options = {
          bucket: Dpkg::S3::Utils.bucket,
          key: s3_path(filename),
          acl: Dpkg::S3::Utils.access_policy,
          content_type: content_type,
          metadata: { 'md5' => file_md5.to_s }
        }
        options[:cache_control] = cache_control unless cache_control.nil?

        # specify if encryption is required
        options[:server_side_encryption] = 'AES256' if Dpkg::S3::Utils.encryption

        # upload the file
        File.open(path) do |f|
          options[:body] = f
          Dpkg::S3::Utils.s3.put_object(options)
        end
      end

      def s3_remove(path)
        return unless s3_exists?(path)

        Dpkg::S3::Utils.s3.delete_object(
          bucket: Dpkg::S3::Utils.bucket,
          key: s3_path(path)
        )
      end
    end
  end
end
