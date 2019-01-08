$stdout.sync = true

require "sinatra/base"

s = Sinatra.new
s.set :bind, "0.0.0.0"
s.set :port, (ENV["PORT"] || "8080")

$__pwd = Dir.pwd
s.get "/" do
  erb :index, locals: { stdout: "", stderr: "", timed_out: false, exitstatus: -1, pwd: $__pwd }
end

s.post "/kill" do
  puts "bye"
  Process.kill "KILL", Process.pid
end

exec_handler = lambda do
  input = params[:input]
  timeout = (params[:timeout]).to_i
  input = ":" if input.nil? || input.empty?
  stdout = nil
  stderr = nil
  timed_out = false
  exitstatus = nil
  begin
    success = false
    Timeout::timeout(timeout) do
      stdout = `cd "#{$__pwd}"; 2> .httpshell_stderr #{input} && pwd || exit 1`
      exitstatus = $?.exitstatus
      success = $?.success?
    end

    stdout = if success
      stdout_lines = stdout.split("\n")
      $__pwd = stdout_lines.pop
      stdout_lines.join "\n"
    else
      stdout
    end
  rescue Timeout::Error
    timed_out = true
  rescue => exception
    p exception
    stdout = exception.to_s
  ensure
    if File.exist? ".httpshell_stderr"
      stderr = File.read ".httpshell_stderr"
      File.unlink ".httpshell_stderr"
    end
  end

  erb :index, locals: { stdout: stdout, stderr: stderr, timed_out: timed_out, exitstatus, exitstatus, pwd: $__pwd }
end

s.post "/exec", &exec_handler
s.get "/exec", &exec_handler

s.run!

