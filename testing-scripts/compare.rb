#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'terminal-table'

def abort(msg)
  puts msg
  exit 1
end

abort("Must pass 2 directories") if (ARGV.count != 2)

dir1 = ARGV[0]
dir2 = ARGV[1]

abort("#{dir1} is not a directory") unless (Dir.exists?(dir1))
abort("#{dir2} is not a directory") unless (Dir.exists?(dir2))


# of expected passes            102533
# of unexpected failures        1280
# of expected failures          19
# of unresolved testcases       124
# of unsupported tests          2583




def read_results(sum_file)
  mapping = {
    "expected passes" => "PASS",
    "unexpected failures" => "FAIL",
    "unexpected successes" => "XPASS",
    "expected failures" => "XFAIL",
    "unresolved testcases" => "UNRESOLVED",
    "unsupported tests" => "UNSUPPORTED"
  }
  ret = {}
  `tail -n 100 #{sum_file}`.split("\n").each do |l|

      if(l =~ /^# of/)

        l = l.split(/( |\t)/).select { |a| a != " " && a != "\t" && a != "" }
        name = l[2..-2].join(" ")
        num = l[-1].to_i

        ret[mapping[name]] = num
      end
  end
  return ret
end

data = {}
keys = nil

table = Terminal::Table.new do |t|

  HEADER = ["", "D(PASS)", "D(FAIL)", "D(NEW)", "D(REM)",
            "PASS", "FAIL", "XFAIL", "XPASS", "UNRESOLVED", "UNSUPPORTED",
            "PASS", "FAIL", "XFAIL", "XPASS", "UNRESOLVED", "UNSUPPORTED"
  ]

  t.headings = ["", { value: "Delta", colspan: 4, alignment: :center },
                    { value: dir1, colspan: 6, alignment: :center },
                    { value: dir2, colspan: 6, alignment: :center }]

  t.add_row HEADER
  t.add_separator

  Dir.children(dir1).sort.each do |d|
    file1 = "#{dir1}/#{d}/gcc.sum"
    file2 = "#{dir2}/#{d}/gcc.sum"
  
    abort("#{file1} does not exist") unless (File.exists?("#{file1}"))
    abort("#{file1} does not exist") unless (File.exists?("#{file2}"))
  
    results1 = read_results(file1)
    results2 = read_results(file2)
    tmp = []
  
    row = [d]
    row[5] = results1["PASS"] || 0
    row[6] = results1["FAIL"] || 0
    row[7] = results1["XFAIL"] || 0
    row[8] = results1["XPASS"] || 0
    row[9] = results1["UNRESOLVED"] || 0
    row[10] = results1["UNSUPPORTED"] || 0
    row[11] = results2["PASS"] || 0
    row[12] = results2["FAIL"] || 0
    row[13] = results2["XFAIL"] || 0
    row[14] = results2["XPASS"] || 0
    row[15] = results2["UNRESOLVED"] || 0
    row[16] = results2["UNSUPPORTED"] || 0
  
    `mkdir -p ./comparisson`
    txt = `ruby sum_compare.rb -v #{file1} #{file2}`
  
    json = JSON.parse(txt)
  
    row[1] = json["results_delta"]["new_pass"]
    row[2] = json["results_delta"]["new_fail"]
    row[3] = json["results_delta"]["add_test"]
    row[4] = json["results_delta"]["rem_test"]
    t.add_row(row)

    ["new_pass", "new_fail", "add_test", "rem_test"].each do |type|
      if(json["changes"][type].values.count > 0)
        tmp.push("  " + type.gsub("_", " ").capitalize)
        json["changes"][type].each_pair do |t, v|
          tmp.push("    (#{v["before"]}) => (#{v["after"]}) : #{t}")
        end
        tmp.push("")
      end
    end

    data[d] = tmp
  end
end

puts table

data.keys.sort.each do |k|
  v = data[k]
  puts "=== #{k} ==="
  puts v.join("\n")
  puts ""
end


