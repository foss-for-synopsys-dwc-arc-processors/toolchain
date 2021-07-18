#!/usr/bin/env ruby

require 'json'
require 'optparse'
@pid = nil
Signal.trap("TERM") do
  if @pid != nil
    puts "Killing process #{@pid}"
    Process.kill("KILL", @pid)
  end
  exit 0
end

def abort(msg)
  puts msg
  exit 1
end
def process_env(str)
  return str.gsub(/\$env\(([A-Z0-9_]+)\)/) do |m|
    puts "----#{$1}"
    abort("Envirnment variable not set #{$1}.") if(ENV[$1].nil?)
    ENV[$1]
  end
end

def read_config(config_file)
  str = File.read(config_file)
  return JSON.parse(str)
end
def prepare_config(hash)
  str = JSON.pretty_generate(hash)
  puts "---${str}---"
  str = process_env(str)
  return JSON.parse(str)
end

def site_exp(config_type, options)
  if(config_type == "baremetal-qemu")
    ret = <<EOF
set tmpdir "./tmp"
set srcdir "#{options["gcc_dir"]}/gcc/testsuite"

set target_triplet #{options["toolchain_tripplet"]}
set target_alias   #{options["target_alias"]}

set tool gcc
set target_list    #{options["target_list"]}

set CFALGS ""
set CXXFLAGS ""

set verbose 0

set arc_board_dir "#{options["toolchain_dir"]}"
if ![info exists boards_dir] {
        lappend boards_dir "$arc_board_dir/dejagnu"
            lappend boards_dir "$arc_board_dir/dejagnu/baseboards"
} else {
      set boards_dir "$arc_board_dir/dejagnu"
          lappend boards_dir "$arc_board_dir/dejagnu/baseboards"
}

#set TIMEOUT_FACTOR 0.1
EOF
    return process_env(ret)
  end
  if(config_type == "linux-qemu")
    ret = <<EOF
  set rootme "."
  set tmpdir "./tmp"
  set srcdir "#{options["gcc_dir"]}/gcc/testsuite"

  set target_triplet #{options["toolchain_tripplet"]}
  set target_alias   #{options["target_alias"]}

  set tool gcc
  set target_board #{options["target_list"]}
  set target_list  #{options["target_list"]}

  set CFLAGS ""
  set CXXFLAGS ""

  set arc_board_dir "#{options["toolchain_dir"]}"
  if ![info exists boards_dir] {
            lappend boards_dir "$arc_board_dir/dejagnu"
                      lappend boards_dir "$arc_board_dir/dejagnu/baseboards"
  } else {
          set boards_dir "$arc_board_dir/dejagnu"
                    lappend boards_dir "$arc_board_dir/dejagnu/baseboards"
  }
EOF
  end
end

def verify_opts(msg, opts, req)
  error = false
  req.each do |r|
    if(opts[r].nil?) 
      error = true
      puts("Option '#{r}' missing for #{msg}.")
    end
  end
  abort("Please fix config file.") if error != false
end

def test_baremetal(name, options)
  verify_opts(name, options, ["qemu_path", "qemu_arch", "extra_env_variables"])
  pwd = Dir.pwd
  workspace_dir = "#{pwd}/workspace/#{options["workspace_dir"]}"
  `mkdir -p #{workspace_dir}/tmp`
  `mkdir -p #{workspace_dir}/dump1`
  `mkdir -p #{workspace_dir}/dump2`
  File.write("#{workspace_dir}/site.exp", site_exp(options['type'], options))
  envs_extra = "#{options[:extra_env_variables]} PATH=#{options["install_dir"]}/bin:$PATH"
  `bash -c "cd #{workspace_dir}; #{envs_extra} export; #{envs_extra} runtest"`
end

def test_linux(name, options)
  verify_opts(name, options, ["qemu_path", "qemu_arch", "extra_env_variables", "linux_image"])
  pwd = Dir.pwd
  workspace_dir = "#{pwd}/workspace/#{options["workspace_dir"]}"
  `mkdir -p #{workspace_dir}/tmp`
  `mkdir -p #{workspace_dir}/dump1`
  `mkdir -p #{workspace_dir}/dump2`

  #Prepare Linux QEMU booting
  
  qemu_opts = "#{options["qemu_opts"]}"
  qemu_cmd = "#{options["qemu_path"]} #{qemu_opts} -kernel #{options["linux_image"]}"
  puts "SPAWN: #{qemu_cmd}"
  @pid = spawn(qemu_cmd, :out => "#{workspace_dir}/qemu.log", :err => "#{workspace_dir}/qemu.err")
  sleep 30
  puts "Finish waiting"

  File.write("#{workspace_dir}/site.exp", site_exp(options['type'], options))
  envs_extra = "#{options[:extra_env_variables]} PATH=#{options["install_dir"]}/bin:$PATH"
  envs_extra += " TARGET_TELNET_PORT=#{options["qemu_telnet_port"]}"
  envs_extra += " TARGET_FTP_PORT=#{options["qemu_ftp_port"]}"
  `bash -c "cd #{workspace_dir}; #{envs_extra} runtest"`

  Process.kill("KILL", @pid)
end

def test(name, options)
  verify_opts(name, options, ["gcc_dir", "toolchain_dir", "install_dir", "workspace_dir"])
  puts "Testing for #{name}"
  if(options["type"] == "baremetal-qemu")
    test_baremetal(name, options)
  elsif(options["type"] == "linux-qemu")
    test_linux(name, options)
  else

  end
end


options = {}
@optparser = OptionParser.new do |opts|
  optbanner = "Usage: test.rb -j <json_config>"

  opts.on("-j FILE", "--json FILE", "Json config file") do |f|
    options[:json] = f
  end
  opts.on("-t TEST", "--test TEST", "Environment tp test") do |t|
    options[:test] = t
  end
  opts.on("-a", "--all", "Test all") do
    options[:test_all] = true
  end
end.parse!

if(options[:json])
  opts = read_config(options[:json])
  if(options[:test_all])
    puts opts
    opts.each_pair do |k, v|
      test(k, prepare_config(v))
    end
  elsif(options[:test] != nil)
    t = options[:test]
    if(opts[t] != nil)
      test(t, prepare_config(opts[t]))
    end
  end   
else
  abort "no options"
end
