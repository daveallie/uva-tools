module UVaTools
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

    def download_multiple(prob_nums, worker_count = 4)
      to_download = Array(prob_nums).map do |prob_num|
        problems_by_number[prob_num]
      end

      if to_download.length > 0
        worker_count = [worker_count, to_download.length].min
        workers = []

        worker_count.times do
          workers << worker(to_download)
        end

        reads = workers.map{|worker| worker[:read]}
        writes = workers.map{|worker| worker[:write]}

        index = 0
        finished = 0

        loop do
          break if finished >= to_download.size

          ready = IO.select(reads, writes)

          ready[0].each do |readable|
            data = Marshal.load(readable)
            # assets.merge! data["assets"]
            # files.merge! data["files"]
            # paths_with_errors.merge! data["errors"]
            finished += 1
          end

          ready[1].each do |write|
            break if index >= to_download.size

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
