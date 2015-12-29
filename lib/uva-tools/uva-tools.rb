module UVaTools
  ROOT_DIR = "#{ENV['HOME']}/uva-tools"
  SAVE_LOCATION = "#{ROOT_DIR}/save"
  USER_SAVE_LOCATION = "#{SAVE_LOCATION}/user"

  class << self
    def problems
      problem_hash.values
    end

    def problems_by_number
      problem_hash
    end

    def problems_by_id
      h = {}
      problem_hash.values.each{ |p| h[p.id] = p }
      h
    end

    def save
      FileUtils::mkdir_p UVaTools::SAVE_LOCATION
      File.open("#{UVaTools::SAVE_LOCATION}/problems", 'w') {|f| f.write(Marshal.dump(problem_hash))}
      true
    end

    def load
      if File.directory?(UVaTools::SAVE_LOCATION) && File.exists?("#{UVaTools::SAVE_LOCATION}/problems")
        @@problems = Marshal.load(File.binread("#{UVaTools::SAVE_LOCATION}/problems"))
        true
      else
        false
      end
    end

    def download_multiple(prob_nums, worker_count = 4)
      to_download = Array(prob_nums).map do |prob_num|
        problems_by_number[prob_num]
      end

      length = to_download.length

      if length > 0
        worker_count = [worker_count, length].min
        workers = []

        worker_count.times do
          workers << worker(to_download)
        end

        reads = workers.map{|worker| worker[:read]}
        writes = workers.map{|worker| worker[:write]}

        index = 0
        finished = 0

        loop do
          break if finished >= length

          ready = IO.select(reads, writes)

          ready[0].each do |readable|
            number = Marshal.load(readable)
            finished += 1
            puts "(#{finished}/#{length}) Finished: #{number}"
          end

          ready[1].each do |write|
            break if index >= length

            Marshal.dump(index, write)
            index += 1
          end
        end

        workers.each do |worker|
          worker[:read].close
          worker[:write].close
        end

        workers.each do |worker|
          Process.wait worker[:pid]
        end
      end

      nil
    end

    private
    def worker(problems)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = fork do
        begin
          parent_write.close
          parent_read.close

          while !child_read.eof?
            problem = problems[Marshal.load(child_read)]
            problem.download
            Marshal.dump(problem.number, child_write)
          end
        ensure
          child_read.close
          child_write.close
        end
      end

      child_read.close
      child_write.close

      {:read => parent_read, :write => parent_write, :pid => pid}
    end

    def problem_hash
      @@problems ||= begin
        uri = URI("http://uhunt.felix-halim.net/api/p")
        res = JSON.parse(Net::HTTP.get(uri))

        h = {}
        res.each{ |row| h[row[1]] = UVaTools::Problem.new(row) }
        h
      end
    end
  end
end
