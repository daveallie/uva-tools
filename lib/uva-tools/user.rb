module UVaTools
  class User
    def self.load(username)
      if File.directory?(UVaTools::USER_SAVE_LOCATION) && File.exists?("#{UVaTools::USER_SAVE_LOCATION}/#{username}")
        Marshal.load(File.binread("#{UVaTools::USER_SAVE_LOCATION}/#{username}"))
      else
        nil
      end
    end

    def initialize(username)
      @username = username
    end

    def solved
      solved_hash.values
    end

    def solved_by_number
      solved_hash
    end

    def unsolved
      @unsolved ||= begin
        prob_by_id = UVaTools.problems_by_id
        unsolved_pids.map do |pid|
          prob_by_id[pid]
        end.sort{ |a, b| b.dacu <=> a.dacu }
      end
    end

    def has_solved?(prob_nums)
      res = Array(prob_nums).map do |prob_num|
        solved_by_number.has_key? prob_num
      end
      res.length < 2 ? res[0] : res
    end

    def reload
      @solved_pids = nil
      @solved = nil
      @unsolved = nil
      self
    end

    def save
      FileUtils::mkdir_p UVaTools::USER_SAVE_LOCATION
      File.open("#{UVaTools::USER_SAVE_LOCATION}/#{@username}", 'w') {|f| f.write(Marshal.dump(self))}
      true
    end

    private
    def uid
      @uid ||= begin
        uri = URI("http://uhunt.felix-halim.net/api/uname2uid/#{@username}")
        Net::HTTP.get(uri)
      end
    end

    def solved_pids
      @solved_pids ||= get_solved_pids
    end

    def solved_hash
      @solved ||= begin
        prob_by_id = UVaTools.problems_by_id
        h = {}
        solved_pids.each do |pid|
          problem = prob_by_id[pid]
          h[problem.number] = problem
        end
        h
      end
    end

    def reload_solved_pids
      @solved_pids = get_solved_pids
    end

    def get_solved_pids
      uri = URI("http://uhunt.felix-halim.net/api/solved-bits/#{uid}")
      res = JSON.parse(Net::HTTP.get(uri))[0]['solved']
      res.each_with_index.map do |num, j|
        num.to_s(2).reverse.scan(/./).each_with_index.map do |c, i|
          j*32 + i if c == '1'
        end.compact
      end.flatten.sort
    end

    def unsolved_pids
      UVaTools.problems.map(&:id) - solved_pids
    end

    def marshal_load array
      @uid, @username, @solved_pids = array
    end

    def marshal_dump
      [uid, @username, solved_pids]
    end
  end
end
