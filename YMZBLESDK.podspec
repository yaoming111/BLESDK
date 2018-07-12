
Pod::Spec.new do |s|

  s.name         = "YMZBLESDK"
  s.version      = "0.0.1"
  s.summary      = "灵活好用的蓝牙低功耗工具"
  s.homepage     = "https://github.com/ymzgithub"
  s.license      = "MIT"
  s.author             = { "Y@o" => "ymz@xkeshi.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "git@github.com:ymzgithub/BLESDK.git", :tag => "0.0.1r" }
  s.source_files  =  "BLESDK/**/*.{h,m}"
  s.exclude_files = ""
  s.requires_arc = true

end
