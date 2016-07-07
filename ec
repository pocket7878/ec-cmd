#!/usr/bin/env ruby

require 'optparse'
require 'pathname'
require 'fileutils'

# Constants
BUNDLE_ID = "jp.poketo7878.ec"
VERSION = "0.1"

option = {}

def osascript(script, async=false)
    if async
        script = "ignoring application responses\n #{script} \nend ignoring"
    end

    stdout = IO.popen(["osascript", "-"], "r+") {|io|
        io.puts script
        io.close_write
        io.gets
    }

    if stdout && stdout.end_with?("\n")
        stdout.chop!
    end

    return stdout
end

def tell(cmd)
    return osascript("tell app \"ec\" to #{cmd}")
end

def win_exists(win_id)
  begin
    res = tell("(first window whose id is #{win_id}) is visible")
    return res == "true"
  rescue
    return false
  end
end

def tell_open_file(file_name, wait=false)
  if wait
    tell("open \"#{file_name}\"")
    win_id = tell('id of window 1')
    puts win_id
    while true
      win_exists = win_exists(win_id)
      if !win_exists
        break
      else
        sleep 0.5
      end
    end
  else
    tell("open \"#{file_name}\"")
  end
end

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

if ARGV.length > 0
  fname = ARGV[0]
  path = Pathname.new(fname)
  if path.exist?
    fname = path.realpath
    tell('run')
    tell_open_file(fname, option[:wait])
    tell('activate')
  elsif option[:new]
    dirpath = path.dirname
    if dirpath
      FileUtils.mkdir_p(dirpath)
    end
    File.open(fname, "w").close()
    path = Pathname.new(fname)
    fname = path.realpath
    tell('run')
    tell_open_file(fname, option[:wait])
    tell('activate')
  else
    STDERR.puts "Error: specified file #{fname} does not exists. Use --new option to create new file."
  end
else
  tell('run')
  tell('activate')
end
