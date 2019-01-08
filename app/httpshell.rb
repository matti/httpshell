$stdout.sync = true

require "sinatra/base"

s = Sinatra.new
s.set :bind, "0.0.0.0"
s.set :port, (ENV["PORT"] || "8080")

$__pwd = Dir.pwd
s.get "/" do
  erb :index, locals: { output: "", pwd: $__pwd }
end

s.post "/kill" do
  puts "bye"
  Process.kill "KILL", Process.pid
end

exec_handler = lambda do
  input = params[:input]
  timeout = (params[:timeout]).to_i
  input = ":" if input.nil? || input.empty?
  output = nil

  begin
    exitstatus = nil
    success = false
    Timeout::timeout(timeout) do
      output = `cd "#{$__pwd}"; #{input} && pwd || exit 1`
      exitstatus = $?.exitstatus
      success = $?.success?
    end

    output = if success
      output_lines = output.split("\n")
      $__pwd = output_lines.pop
      output_lines.join "\n"
    else
      "exit: #{exitstatus}"
    end
  rescue Timeout::Error
    output = "!!! timeout after #{timeout}s"
  rescue => exception
    output = exception.to_s
  end

  erb :index, locals: { output: output, pwd: $__pwd }
end

s.post "/exec", &exec_handler
s.get "/exec", &exec_handler

s.run!

