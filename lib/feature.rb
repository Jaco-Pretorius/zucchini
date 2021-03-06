class Zucchini::Feature
  attr_accessor :path
  attr_reader :device
  attr_accessor :template
  attr_accessor :stats
  
  attr_reader :succeeded
  attr_reader :name   
  
  def initialize(path, device)
    @path      = path
    @device    = device
    @succeeded = false
  end

  def name
    File.basename(@path)
  end
  
  def run_data_path
     "#{@path}/run_data" 
  end     

  def unmatched_pending_screenshots
    Dir.glob("#{@path}/pending/#{@device.screen}/[^0-9]*.png").map do |file|
      screenshot = Zucchini::Screenshot.new(file, nil, true)
      screenshot.test_path = File.expand_path(file)
      screenshot.diff = [:pending, "unmatched"]
      screenshot
    end
  end
  
  def screenshots(process = true)
    @screenshots ||= Dir.glob("#{run_data_path}/Run\ 1/*.png").map do |file|
      screenshot = Zucchini::Screenshot.new(file, @device)
      if process
        screenshot.rotate
        screenshot.mask
        screenshot.compare
      end
      screenshot
    end + unmatched_pending_screenshots
  end
  
  def stats
    @stats ||= screenshots.inject({:passed => [], :failed => [], :pending => []}) do |stats, s|
      stats[s.diff[0]] << s
      stats
    end
  end                     
  
  def compile_js
    zucchini_base_path = File.expand_path("#{File.dirname(__FILE__)}/..")
  
    feature_text = File.open("#{@path}/feature.zucchini").read.gsub(/\#.+[\z\n]?/,"").gsub(/\n/, "\\n")
    File.open("#{run_data_path}/feature.coffee", "w+") { |f| f.write("Zucchini.run('#{feature_text}')") }

    cs_paths  = "#{zucchini_base_path}/lib/uia #{@path}/../support/screens"
    cs_paths += " #{@path}/../support/lib" if File.exists?("#{@path}/../support/lib")
    cs_paths += " #{run_data_path}/feature.coffee"
    
    `coffee -o #{run_data_path} -j #{run_data_path}/feature.js -c #{cs_paths}`
  end

  def collect
    with_setup do      
      `rm -rf #{run_data_path}/*`
      compile_js
    
      device_params = @device.is_simulator? ? "" : "-w #{@device.udid}"
      
      begin
        out = `instruments #{device_params} -t "#{@template}" "#{Zucchini::Config.app}" -e UIASCRIPT "#{run_data_path}/feature.js" -e UIARESULTSPATH "#{run_data_path}" 2>&1`
        puts out
        # Hack. Instruments don't issue error return codes when JS exceptions occur
        raise "Instruments run error" if (out.match /JavaScript error/) || (out.match /Instruments\ .{0,5}\ Error\ :/ )
      ensure
        `rm -rf instrumentscli*.trace`  
      end
    end
  end

  def compare
    `rm -rf #{run_data_path}/Diff/*`
    @succeeded = (stats[:failed].length == 0)
  end

  def with_setup
    setup = "#{@path}/setup.rb"
    if File.exists?(setup)             
      require setup 
      begin
        Setup.before { yield }
      ensure
        Setup.after
      end
    else
      yield
    end
  end

  def approve(reference_type)
    raise "Directory #{path} doesn't contain previous run data" unless File.exists?("#{run_data_path}/Run\ 1")

    screenshots(false).each do |s|
      reference_file_path = "#{File.dirname(s.file_path)}/../../#{reference_type}/#{device.screen}/#{s.file_name}"
      FileUtils.mkdir_p File.dirname(reference_file_path)
      @succeeded = FileUtils.copy_file(s.file_path, reference_file_path)
    end
  end
end
