Pod::Spec.new do |s|
  s.name = 'SpokeStack'
  s.version = '0.3.0'
  s.license = 'Apache'
  s.summary = 'Spokestack provides an extensible speech recognition pipeline for the iOS platform.'
  s.homepage = 'https://www.pylon.com'
  s.authors = { 'Spokestack' => 'support@pylon.com' }
  s.source = { :git => 'https://github.com/pylon/spokestack-ios.git', :tag => '0.3.0' }
  s.license = {:type => 'Apache', :file => 'LICENSE'}
  s.ios.deployment_target = '11.0'
  s.swift_version = '4.2'
  s.ios.framework = 'AVFoundation'
  s.source_files = 'SpokeStack/*'
  s.exclude_files = 'SpokeStackFrameworkExample/*.*', 'SpokeStackTests/*.*', 'SpokeStack/Info.plist'
end
