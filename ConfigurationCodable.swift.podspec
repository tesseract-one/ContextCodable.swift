Pod::Spec.new do |s|
  s.name             = 'ConfigurationCodable.swift'
  s.version          = '0.1.0'
  s.summary          = 'Backport of CodableWithConfiguration to old OS versions and Linux'

  s.description      = <<-DESC
  CodableWithConfiguration ported to older versions of Apple operating systems and Linux
                       DESC

  s.homepage         = 'https://github.com/tesseract-one/ConfigurationCodable.swift'

  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/ConfigurationCodable.swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '11.0'
  s.watchos.deployment_target = '4.0'
  
  s.swift_version = '5.4'

  s.module_name = 'ConfigurationCodable'
  
  s.source_files = 'Sources/ConfigurationCodable/**/*.swift'
  
  s.test_spec 'Tests' do |test_spec|
    test_spec.platforms = {:ios => '11.0', :osx => '10.12', :tvos => '11.0'}
    test_spec.source_files = 'Tests/ConfigurationCodableTests/*.swift'
  end
end
