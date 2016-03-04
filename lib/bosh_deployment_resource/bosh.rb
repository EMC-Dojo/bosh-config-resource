require "json"
require "pty"

module BoshDeploymentResource
  class Bosh
    def initialize(target, auth, command_runner=CommandRunner.new)
      @target = target
      @auth = auth
      @command_runner = command_runner
    end

    def upload_stemcell(path)
      bosh("upload stemcell #{path} --skip-if-exists")
    end

    def upload_release(path)
      bosh("upload release #{path} --skip-if-exists")
    end

    def deploy(manifest_path)
      bosh("-d #{manifest_path} deploy")
    end

    def cleanup
      bosh("cleanup")
    end

    def director_uuid
      r, w = IO.pipe
      bosh("status --uuid", out: w)
      r.gets.strip
    ensure
      r.close
      w.close
    end

    private

    attr_reader :target, :command_runner

    def bosh(command, opts={})
      run(
        "bosh -n --color -t #{target} #{command}",
        @auth.env,
        opts,
      )
    end

    def run(command, env={}, opts={})
      command_runner.run(command, env, opts)
    end
  end

  class CommandRunner
    def run(command, env={}, opts={})
      pid = Process.spawn(env, command, { out: :err, err: :err }.merge(opts))
      Process.wait(pid)
      raise "command '#{command}' failed!" unless $?.success?
    end
  end
end
