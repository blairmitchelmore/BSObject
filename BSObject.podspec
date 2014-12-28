#
# Be sure to run `pod lib lint BSObject.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "BSObject"
  s.version          = "0.1.1"
  s.summary          = "An object designed to map subclasses to json data automatically"
  s.description      = <<-DESC
                       BSObject lets you create objects that will automatically
                       build themselves from json data and will also automatically
                       export json data
                       DESC
  s.homepage         = "https://github.com/blairmitchelmore/BSObject"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Blair Mitchelmore" => "blair.mitchelmore@gmail.com" }
  s.source           = { :git => "https://github.com/blairmitchelmore/BSObject.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/bmitchelmore'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'BSObject' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
