

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
  s.source       = { :git => "https://github.com/peterbober/ZTSJTask.git", :branch => "master" }
  s.source_files  = "ZTLMHttpTask", "ZTLMHttpTask/Classes/*.{h,m}"
  s.requires_arc = true

end
