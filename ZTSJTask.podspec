

Pod::Spec.new do |s|


  s.name         = "ZTSJTask"
  s.version      = "0.0.1"
  s.summary      = "HTTP TASK"
  s.description  = <<-DESC
                      ZTSJTask.
                      DESC
  s.homepage     = "https://github.com/peterbober/ZTLaborManage.git"
  s.license        = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "peterbober" => "chenpengpoli@gmail.com" }
  s.source       = { :git => "https://github.com/peterbober/ZTSJTask.git", :tag => "0.0.1" }
  s.source_files  = "Classes", "Classes/*.{h,m}"
  s.exclude_files = "Classes/"
  s.requires_arc = true
  
end
