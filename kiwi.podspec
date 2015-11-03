Pod::Spec.new do |spec|
  spec.name         = 'kiwi'
  spec.version      = '0.0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/mconintet/kiwi-objc'
  spec.authors      = { 'mconintet' => 'mconintet@gmail.com' }
  spec.summary      = 'Client component of WebSocket in Objective-C.'
  spec.source       = { :git => 'https://github.com/mconintet/kiwi-objc.git', :tag => '0.0.1' }
  spec.source_files = 'kiwi'
  spec.ios.deployment_target = '9.0'
end