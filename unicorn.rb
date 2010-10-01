# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes 2

# working_directory "."

## Listen on port 80, no unix domain socket stuff required
listen 8080, :tcp_nopush => true

# nuke workers after 10 seconds instead of 60 seconds (the default)
timeout 10

pid "unicorn.pid"

stderr_path "unicorn.stderr.log"
stdout_path "unicorn.stdout.log"

preload_app true

GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true
  
before_fork do |server, worker|
    ##
    # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
    # immediately start loading up a new version of itself (loaded with a new
    # version of our app). When this new Unicorn is completely loaded
    # it will begin spawning workers. The first worker spawned will check to
    # see if an .oldbin pidfile exists. If so, this means we've just booted up
    # a new Unicorn and need to tell the old one that it can now die. To do so
    # we send it a QUIT.
    #
    # Using this method we get 0 downtime deploys.
    #old_pid = "#{server.config[:pid]}.oldbin"

    #if File.exists?(old_pid) && server.pid != old_pid
    #  begin
    #    sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
    #    Process.kill(sig, File.read(old_pid).to_i)
    #  rescue Errno::ENOENT, Errno::ESRCH
        # someone else did our job for us
    #  end
    #end
end
