#!/usr/bin/env ruby

require 'json'

HELP_MESSAGE =<<EOF
usage: ruby ./sum_compare.rb [-v] [-a anotate_file] <file1> <file2>
EOF

@enable_logging = false
@filters = {}

def process_options()
  while(ARGV[0] =~ /^-[a-z]$/)
    opt = ARGV.shift
    if(opt == '-v')
      @enable_logging = true
    elsif(opt == '-a')
      filename = ARGV.shift
      @filters = JSON.parse(File.read(filename))
    end
  end

  if(ARGV.length != 2)
    puts HELP_MESSAGE
    exit -1
  end

end

FAILING_SENARIOS = ["FAIL", "UNSUPPORTED", "XPASS", "UNRESOLVED"]
PASSING_SENARIOS = ["PASS", "XFAIL"]

def parse_sum(filename)
  #valid_results = FAILING_SENARIOS & PASSING_SENARIOS
  valid_results = ['PASS', 'FAIL', 'XFAIL', 'XPASS', 'UNRESOLVED', 'UNSUPPORTED']
  content = File.read(filename)
  data = {}
  content.each_line do |l|
    if(l =~ /([A-Z]+): (.+)/)
      if(data[$2] == nil)
        data[$2] = $1 if(valid_results.include?($1))
      elsif(valid_results.include?($1))
        count = 1
        tmp = "#{$2} (#{count})"
        while(data[tmp] != nil)
          count += 1
          tmp = "#{$2} (#{count})"
        end
        data[tmp] = data[$2] = $1
      end
    end
  end
  return data
end



@ret = {
  changes: {},

  baseline_results: {
    pass: 0,
    fail: 0,
    not_considered: 0
  },
  results: {
    pass: 0,
    fail: 0,
    not_considered: 0
  },
  results_delta: {
    new_fail: 0,
    new_pass: 0,
    add_test: 0,
    rem_test: 0
  },
  filtered_results: {
    new_fail: 0,
    new_pass: 0,
    add_test: 0,
    rem_test: 0
  }
}

def analyse_test(test, r1, r2, filter)
  entry = nil

  filter["known_to_fail"] = filter["known_to_fail"] || {}
  filter["flacky_tests"] = filter["flacky_tests"] || {}
  filter["filter_out"] = {} unless filter["filter_out"]
  filter_report = filter["filter_out"][test]
  reason_filter = ""
  reason_filter += filter["filter_out"][test].to_s if filter["filter_out"]
  reason_filter += filter["comments"][test].to_s if filter["comments"]

  if(r1 != nil)
    @ret[:baseline_results][:pass] += 1 if (PASSING_SENARIOS.include?(r1))
    @ret[:baseline_results][:fail] += 1 if (FAILING_SENARIOS.include?(r1))
    @ret[:baseline_results][:not_considered] += 1 if ((!PASSING_SENARIOS.include?(r1) && !FAILING_SENARIOS.include?(r1)))
    puts "#{test} = OTHER #{r1}" unless (PASSING_SENARIOS.include?(r1) || FAILING_SENARIOS.include?(r1))
  end
  if(r2 != nil)
    @ret[:results][:pass] += 1 if (PASSING_SENARIOS.include?(r2))
    @ret[:results][:fail] += 1 if (FAILING_SENARIOS.include?(r2))
    @ret[:baseline_results][:not_considered] += 1 if ((!PASSING_SENARIOS.include?(r2) && !FAILING_SENARIOS.include?(r2)))
    puts "#{test} = OTHER #{r1}" unless (PASSING_SENARIOS.include?(r2) || FAILING_SENARIOS.include?(r2))
  end


  if(r2 == nil && r1 != nil)
    #puts "REM_TEST: #{test}    (#{r1} => (null))" if @enable_logging
    @ret[:changes][test] = { before: r1, after: "(null)", comments: reason_filter }
    @ret[:results_delta][:rem_test] += 1 unless filter_report
    @ret[:filtered_results][:rem_test] += 1 if filter_report
  elsif(r1 == nil && r2 != nil)
    #puts "ADD_TEST: #{test}   ((null) => #{r2})" if @enable_logging
    @ret[:changes][test] = { before: "(null)", after: r2, comments: reason_filter }
    @ret[:results_delta][:add_test] += 1 unless filter_report
    @ret[:filtered_results][:add_test] += 1 if filter_report
  end

  if((r1 == 'FAIL' || r1 == 'UNRESOLVED' || r1 == nil) && r2 == 'PASS')
    #puts "NEWLY_PASS: #{test}   (#{r1} => #{r2})" if @enable_logging
    @ret[:changes][test] = { before: r1, after: r2, comments: reason_filter }
    @ret[:results_delta][:new_pass] += 1 unless filter_report
    @ret[:filtered_results][:new_pass] += 1 if filter_report
  elsif((r1 == 'PASS' || r1 == nil) && (r2 == 'FAIL' || r2 == 'UNRESOLVED'))
    #puts "NEWLY_FAIL: #{test}   (#{r1} => #{r2})" if @enable_logging
    @ret[:changes][test] = { before: r1, after: r2, comments: reason_filter }
    @ret[:results_delta][:new_fail] += 1 unless filter_report
    @ret[:filtered_results][:new_fail] += 1 if filter_report
  elsif(r1 == 'UNSUPPORTED' && r1 != r2)
    #puts "ADD_TEST: #{test}   (#{r1} => #{r2})" if @enable_logging
    @ret[:changes][test] = { before: r1, after: r2, comments: reason_filter }
    @ret[:results_delta][:add_test] += 1 unless filter_report
    @ret[:filtered_results][:add_test] += 1 if filter_report
  elsif(r2 == 'UNSUPPORTED' && r1 != r2)
    #puts "REM_TEST: #{test}   (#{r1} => #{r2})" if @enable_logging
    @ret[:changes][test] = { before: r1, after: r2, comments: reason_filter }
    @ret[:results_delta][:rem_test] += 1 unless filter_report
    @ret[:filtered_results][:rem_test] += 1 if filter_report
  end
end

process_options
data1 = parse_sum(ARGV[0])
data2 = parse_sum(ARGV[1])

File.write("debug.json", JSON.pretty_generate(data1))

tests1 = data1.keys
tests2 = data2.keys

tests_added = tests2 - tests1
tests_removed   = tests1 - tests2

i1 = 0
i2 = 0
while(true)
  test1 = tests1[i1]
  test2 = tests2[i2]

  break if(test1.nil? && test2.nil?)

  if(test1 == test2)
    analyse_test(test1, data1[test1], data2[test1], @filters)
    i1 += 1
    i2 += 1
  else
    if(tests_added.include?(test2))
      analyse_test(test2, nil, data2[test2], @filters)
      i2 += 1
    elsif(tests_removed.include?(test1))
      analyse_test(test1, data1[test1], nil, @filters)
      i1 += 1
    end
  end


end

#data1.keys.merge(data1.keys).each do |test|
#  analyse_test(test, data1[test], data2[test])
#end

puts JSON.pretty_generate(@ret)

