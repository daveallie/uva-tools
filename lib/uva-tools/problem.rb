=begin
 0: Problem ID
 1: Problem Number
 2: Problem Title
 3: Number of Distinct Accepted User (DACU)
 4: Best Runtime of an Accepted Submission
 5: Best Memory used of an Accepted Submission
 6: Number of No Verdict Given (can be ignored)
 7: Number of Submission Error
 8: Number of Can't be Judged
 9: Number of In Queue
10: Number of Compilation Error
11: Number of Restricted Function
12: Number of Runtime Error
13: Number of Output Limit Exceeded
14: Number of Time Limit Exceeded
15: Number of Memory Limit Exceeded
16: Number of Wrong Answer
17: Number of Presentation Error
18: Number of Accepted
19: Problem Run-Time Limit (milliseconds)
20: Problem Status (0 = unavailable, 1 = normal, 2 = special judge)
=end

module UVaTools
  class Problem
    def initialize(a)
      @info = {
        id: a[0],
        number: a[1],
        title: a[2],
        dacu: a[3],
        submitted: a[6..18].inject(:+),
        accepted: a[18],
        run_time: a[19]
      }
    end

    def info_raw
      @info
    end

    def info
      {
        id: id,
        number: number,
        title: title,
        run_time: run_time
      }
    end

    def submission_info
      {
        submitted: submitted,
        accepted: accepted,
        dacu: dacu
      }
    end

    def download
      unless downloaded?
        FileUtils::mkdir_p dir_name
        Dir.chdir(dir_name) do
          uri = URI("https://uva.onlinejudge.org/external/#{number/100}/#{number}.html")
          source = Net::HTTP.get(uri)
          if source.include? "URL=p#{number}.pdf"
            File.open("#{number.to_s}.pdf", 'w') do |pdf|
              pdf.write open("https://uva.onlinejudge.org/external/#{number/100}/p#{number}.pdf").read
            end
          else
            File.open("#{number.to_s}.html", 'w') { |f| f.write source }

            source.scan(/#{number}img\d{1,3}\.[a-zA-Z]+/).uniq.each do |picture|
              File.open(picture, 'wb') do |pic_file|
                pic_file.write open("https://uva.onlinejudge.org/external/#{number/100}/#{picture}").read
              end
            end
          end
        end
        true
      else
        false
      end
    end

    def remove
      if downloaded?
        Dir.chdir(dir_name) do
          Dir.entries('.').each do |file_name|
            if file_name =~ /^#{number}.*/ && !File.directory?(file_name)
              File.delete(file_name)
            end
          end
        end
        true
      else
        false
      end
    end

    def downloaded?
      File.directory?(dir_name) && (File.exists?("#{dir_name}/#{number}.html") || File.exists?("#{dir_name}/#{number}.pdf"))
    end

    def open_problem
      if f_path = path
        `open #{f_path}`
        true
      else
        puts "Problem not downloaded!"
        false
      end
    end

    private
    def dir_name
      "#{UVaTools::ROOT_DIR}/#{number/100}"
    end

    def path
      if downloaded?
        "#{dir_name}/#{number}.#{File.exists?("#{dir_name}/#{number}.html") ? 'html' : 'pdf'}"
      else
        nil
      end
    end

    def method_missing(method_name, *args, &block)
      if @info.has_key? method_name
        @info[method_name]
      else
        super(method_name, *args, &block)
      end
    end
  end
end
