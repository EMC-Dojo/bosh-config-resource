require 'digest'
require 'time'

module BoshConfigResource
  class OutCommand
    def initialize(bosh, manifest, writer = STDOUT)
      @bosh = bosh
      @manifest = manifest
      @writer = writer
    end

    def run(working_dir, request)
      validate! request

      if request.fetch('source').fetch('type') == "runtime-config"

        releases = []
        find_releases(working_dir, request).each do |release_path|

          release = BoshRelease.new(release_path)
          manifest.use_release(release)
          bosh.upload_release(release_path)

          releases << release
        end

        new_manifest = manifest.write!

        bosh.update_runtime_config(new_manifest.path)

        response = {
            'version' => {
                'manifest_sha1' => manifest.shasum,
                'target' => bosh.target
            },
            'metadata' =>
                releases.map { |r| { 'name' => 'release', 'value' => "#{r.name} v#{r.version}" } }
        }

      elsif request.fetch('source').fetch('type') == "cloud-config"

        new_manifest = manifest.write!

        bosh.update_cloud_config(new_manifest.path)

        response = {
            'version' => {
                'manifest_sha1' => manifest.shasum,
                'target' => bosh.target
            }
        }

      else
        raise "'source.type' must equal 'runtime-config' or 'cloud-config'"
      end


      writer.puts response.to_json
    end

    private

    attr_reader :bosh, :manifest, :writer

    def validate!(request)
      %w(manifest releases).each do |field|
        request.fetch('params').fetch(field) { raise "params must include '#{field}'" }
      end

      raise 'releases must be an array of globs' unless enumerable?(request.fetch('params').fetch('releases'))
    end

    def find_releases(working_dir, request)
      globs = request
              .fetch('params')
              .fetch('releases')

      glob(working_dir, globs)
    end

    def glob(working_dir, globs)
      paths = []

      globs.each do |glob|
        abs_glob = File.join(working_dir, glob)
        results = Dir.glob(abs_glob)

        raise "glob '#{glob}' matched no files" if results.empty?

        paths.concat(results)
      end

      paths.uniq
    end

    def enumerable?(object)
      object.is_a? Enumerable
    end
  end
end
