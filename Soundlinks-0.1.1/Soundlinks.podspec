Pod::Spec.new do |s|
  s.name = 'Soundlinks'
  s.version = '0.1.1'
  s.summary = 'Soundlinks SDK'
  s.license = 'MIT'
  s.authors = {"liqingyao"=>"qingyao.li@yahoo.com"}
  s.homepage = 'https://github.com/liqingyao/Soundlinks'
  s.description = 'Soundlinks SDK provides APIs for parsing contents from audios which are carried inaudible information.'
  s.frameworks = ["Foundation", "QuartzCore", "AudioToolbox", "AVFoundation", "UIKit"]
  s.requires_arc = true
  s.source = {}

  s.platform = :ios, '7.0'
  s.ios.platform             = :ios, '7.0'
  s.ios.preserve_paths       = 'ios/Soundlinks.framework'
  s.ios.public_header_files  = 'ios/Soundlinks.framework/Versions/A/Headers/*.h'
  s.ios.resource             = 'ios/Soundlinks.framework/Versions/A/Resources/**/*'
  s.ios.vendored_frameworks  = 'ios/Soundlinks.framework'
end
