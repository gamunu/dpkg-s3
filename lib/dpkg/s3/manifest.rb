# frozen_string_literal: true

require 'tempfile'
require 'zlib'
require 'dpkg/s3/utils'
require 'dpkg/s3/package'

# Dpkg is the root module for all storage modules including S3
module Dpkg
  # S3 storage module resposible of handling packages on S3 including upload, delete
  module S3
    # Manifest is resposible of creating/retrieving and rebuilding the debian Package manifest with
    # standard information required when publishing the packages to a S3 debian repository
    class Manifest
      include Dpkg::S3::Utils

      attr_accessor :codename, :component, :cache_control, :architecture, :fail_if_exists, :skip_package_upload, :files

      attr_reader :packages, :packages_to_be_upload

      def initialize
        @packages = []
        @packages_to_be_upload = []
        @component = nil
        @architecture = nil
        @files = {}
        @cache_control = ''
        @fail_if_exists = false
        @skip_package_upload = false
      end

      class << self
        def retrieve(codename, component, architecture, cache_control, fail_if_exists, skip_upload: false)
          m = if (s = Dpkg::S3::Utils.s3_read("dists/#{codename}/#{component}/binary-#{architecture}/Packages"))
                parse_packages(s)
              else
                new
              end

          m.codename = codename
          m.component = component
          m.architecture = architecture
          m.cache_control = cache_control
          m.fail_if_exists = fail_if_exists
          m.skip_package_upload = skip_upload
          m
        end

        def parse_packages(str)
          m = new
          str.split("\n\n").each do |s|
            next if s.chomp.empty?

            m.packages << Dpkg::S3::Package.parse_string(s)
          end
          m
        end
      end

      def add(pkg, preserve_versions, needs_uploading: true)
        if fail_if_exists
          packages.each do |p|
            next unless p.name == pkg.name && \
                        p.full_version == pkg.full_version && \
                        File.basename(p.url_filename(@codename)) == \
                        File.basename(pkg.url_filename(@codename))

            raise AlreadyExistsError,
                  "package #{pkg.name}_#{pkg.full_version} already exists " \
                  "with filename (#{p.url_filename(@codename)})"
          end
        end
        if preserve_versions
          packages.delete_if { |p| p.name == pkg.name && p.full_version == pkg.full_version }
        else
          packages.delete_if { |p| p.name == pkg.name }
        end
        packages << pkg
        packages_to_be_upload << pkg if needs_uploading
        pkg
      end

      def delete_package(pkg, versions = nil)
        new_packages = @packages.select do |p|
          # Include packages we didn't name
          # Also include the packages not matching a specified version
          if p.name != pkg || (!versions.nil? && (p.name == pkg) && !versions.include?(p.version) &&
                !versions.include?("#{p.version}-#{p.iteration}") && !versions.include?(p.full_version))
            p
          end
        end
        deleted = @packages - new_packages
        @packages = new_packages
        deleted
      end

      def generate
        @packages.collect { |pkg| pkg.generate(@codename) }.join("\n")
      end

      def write_to_s3
        manifest = generate

        unless skip_package_upload
          # store any packages that need to be stored
          @packages_to_be_upload.each do |pkg|
            yield pkg.url_filename(@codename) if block_given?
            s3_store(pkg.filename, pkg.url_filename(@codename), 'application/x-debian-package', cache_control,
                     fail_if_exists: fail_if_exists)
          end
        end

        # generate the Packages file
        pkgs_temp = Tempfile.new('Packages')
        pkgs_temp.write manifest
        pkgs_temp.close
        f = "dists/#{@codename}/#{@component}/binary-#{@architecture}/Packages"
        yield f if block_given?
        s3_store(pkgs_temp.path, f, 'text/plain; charset=utf-8', cache_control)
        @files["#{@component}/binary-#{@architecture}/Packages"] = hashfile(pkgs_temp.path)
        pkgs_temp.unlink

        # generate the Packages.gz file
        gztemp = Tempfile.new('Packages.gz')
        gztemp.close
        Zlib::GzipWriter.open(gztemp.path) { |gz| gz.write manifest }
        f = "dists/#{@codename}/#{@component}/binary-#{@architecture}/Packages.gz"
        yield f if block_given?
        s3_store(gztemp.path, f, 'application/x-gzip', cache_control)
        @files["#{@component}/binary-#{@architecture}/Packages.gz"] = hashfile(gztemp.path)
        gztemp.unlink

        nil
      end

      def hashfile(path)
        {
          size: File.size(path),
          sha1: Digest::SHA1.file(path).hexdigest,
          sha256: Digest::SHA2.file(path).hexdigest,
          md5: Digest::MD5.file(path).hexdigest
        }
      end
    end
  end
end
