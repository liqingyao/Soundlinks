#
# Be sure to run `pod lib lint Soundlinks.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Soundlinks"
  s.version          = "0.1.4"
  s.summary          = "Soundlinks SDK"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                        Soundlinks SDK provides APIs for parsing contents from audios which are carried inaudible information.
                       DESC

  s.homepage         = "https://github.com/liqingyao/Soundlinks"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "liqingyao" => "qingyao.li@yahoo.com" }
  s.source           = { :git => "/Users/liqingyao/Documents/Bitbucket/Soundlinks", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

# For Debug
#  s.source_files = 'Pod/Classes/**/*.{h,m,mm}'
#  s.public_header_files = 'Pod/Classes/**/*.h'

# For Library
  s.source_files = 'Pod/Classes/**/Soundlinks.h'
  s.public_header_files = 'Pod/Classes/**/Soundlinks.h'
  s.preserve_paths = 'Pod/Classes/**/libSoundlinks.a'
  s.ios.vendored_library = 'Pod/Classes/**/libSoundlinks.a'

  s.frameworks = 'Foundation', 'QuartzCore', 'AudioToolbox', 'AVFoundation', 'UIKit'

# s.libraries = 'stdc++'
# s.resource_bundles = {
#    'Soundlinks' => ['Pod/Assets/*.png']
#  }
# s.dependency 'AFNetworking', '~> 2.3'

end
