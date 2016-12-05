#!/usr/bin/env ruby

require 'optparse'
require 'pathname'
require 'fileutils'

# Constants
BUNDLE_ID = "jp.poketo7878.ec"
VERSION = "0.1"

option = {}

class OsascriptError < Exception; end

def osascript(script, async=false)
    if async
        script = "ignoring application responses\n #{script} \nend ignoring"
    end

    stdout = IO.popen(["osascript", "-"], "r+", :err => [:child, :out]) {|io|
        io.puts script
        io.close_write
        io.gets
    }

    if $?.to_i != 0
        raise OsascriptError
    end

    if stdout && stdout.end_with?("\n")
        stdout.chop!
    end

    return stdout
end

class Ec
  def initialize
    @name = "Ec"
    @bundle_id = osascript("id of app \"#{@name}\"")
  end

  def launch()
    tell('activate')
  end

  def open_file(path)
    path = path.to_s.gsub('"', '\\"')
    tell("open POSIX file \"#{path}\"", true)
  end

  def window_id(index = 1)
    tell("id of window #{index}")
  end

  def window_exists?(winid)
    result = nil
    begin
      result = tell("(first window whose id is #{winid}) is visible")
    rescue ::OsascriptError
    end
    return result == "true"
  end

  private
  def tell(cmd, async=false)
    return osascript("tell app \"#{@name}\" to #{cmd}", async)
  end

end

if __FILE__ == $0

  OptionParser.new do |opt|
      opt.on('-n', '--new') { |v| option[:new] = v }
      opt.on('-w', '--wait') { |v| option[:wait] = v }
      opt.on('-v', '--version') { |v| option[:version] = v }
      opt.permute!(ARGV)
  end

  if option[:version]
      STDERR.puts "ec #{VERSION}"
      exit 0
  end

  # First Launch application
  ec = Ec.new()
  ec.launch

  if ARGV.length > 0

    fname = ARGV[0]
    path = Pathname.new(fname)
    if path.exist?
      full_path = path.realpath
      ec.open_file(full_path)
    elsif option[:new]
      dirpath = path.dirname
      if dirpath
        FileUtils.mkdir_p(dirpath)
      end
      # Create new file
      File.open(fname, "w").close()
      path = Pathname.new(fname)
      full_path = path.realpath
      ec.open_file(full_path)
    else
      STDERR.puts "Error: specified file #{fname} does not exists. Use --new option to create new file."
      exit 1
    end

    if fname && option[:wait]
      winid = ec.window_id
      while ec.window_exists?(winid)
        sleep(0.5)
      end
    end

  end

end
