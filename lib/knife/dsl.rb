require 'chef/application/knife'
require 'knife/dsl/version'
require 'stringio'

module Chef::Knife::DSL
  module Chef::Knife::DSL::Support
    def self.run_knife(command, args)
      unless command.kind_of?(Array)
        command = command.to_s.split(/[\s_]+/)
      end

      command += args

      if ENV["CHEF_CONFIG"]
        command += ['-c', ENV["CHEF_CONFIG"]]
      end

      opts = Chef::Application::Knife.new.options
      Chef::Knife.run(command, opts)
      return 0
    rescue SystemExit => e
      return e.status
    end
  end

  def knife(command, args=[])
    Chef::Knife::DSL::Support.run_knife(command, args)
  end

  def knife_capture(command, args=[], input=nil)
    null = Gem.win_platform? ? File.open('NUL:', 'r') : File.open('/dev/null', 'r')

    warn = $VERBOSE 
    $VERBOSE = nil
    old_stderr, old_stdout, old_stdin = $stderr, $stdout, $stdin

    $stderr = StringIO.new('', 'r+')
    $stdout = StringIO.new('', 'r+')
    $stdin = input ? StringIO.new(input, 'r') : null
    $VERBOSE = warn

    status = Chef::Knife::DSL::Support.run_knife(command, args)
    return $stdout.string, $stderr.string, status
  ensure
    warn = $VERBOSE 
    $VERBOSE = nil
    $stderr = old_stderr
    $stdout = old_stdout
    $stdin = old_stdin
    $VERBOSE = warn
    null.close
  end
end

class << eval("self", TOPLEVEL_BINDING)
  include Chef::Knife::DSL
end

if defined? Rake::DSL
  module Rake::DSL
    include Chef::Knife::DSL
  end
end
