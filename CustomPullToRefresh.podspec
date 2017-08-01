
Pod::Spec.new do |s|
  s.name         = "CustomPullToRefresh"
  s.version      = "0.0.1"
  s.summary      = "CustomPullToRefresh from SVPullToRefresh"
  s.description  = <<-DESC
  a custom pull to refresh tool
                    DESC
  s.homepage     = "https://github.com/rawlinxx/CustomPullToRefresh.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Rawlinxx" => "rawlinxx@gmail.com" }
  s.platform     = :ios, "5.0"
  s.source       = { :git => "https://github.com/rawlinxx/CustomPullToRefresh.git", :tag => "#{s.version}" }
  s.source_files  = "Classes/**/*"
end
