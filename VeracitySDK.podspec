#
# Be sure to run `pod lib lint VeracitySDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VeracitySDK'
  s.version          = '0.2.0'
  s.summary          = 'Developed by Veracity Protocol.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/oneprove/ios-sdk-public'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'minh' => 'minh@veracityprotocol.org' }
  s.source           = { :git => 'https://github.com/oneprove/ios-sdk-public', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.requires_arc = true
  s.swift_version = "5.0"
  s.pod_target_xcconfig = {'DEFINES_MODULE' => 'YES'}
  s.static_framework = true
  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  
  s.source_files = 'VeracitySDK/Classes/VeracitySDK.xcframework/**/VeracitySDK.framework/Headers/*.h'
  s.public_header_files = 'VeracitySDK/Classes/VeracitySDK.xcframework/**/VeracitySDK.framework/Headers/*.h'
  
  s.vendored_frameworks = 'VeracitySDK/Classes/*.xcframework'
  
  s.dependency "RealmSwift"
  s.dependency "SwiftyJSON"
  s.dependency "ObjectMapper"
  s.dependency "ObjectMapperAdditions/Realm"
  s.dependency "ReachabilitySwift"
  s.dependency 'OpenCV', '3.4.6'
  s.dependency 'SnapKit'
  s.dependency 'Smartlook'
  s.dependency 'SDWebImage'
  
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  
end
