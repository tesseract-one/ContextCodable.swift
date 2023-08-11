Pod::Spec.new do |s|
  s.name             = 'ContextCodable.swift'
  s.version          = '999.99.9'
  s.summary          = 'Backport of CodableWithConfiguration to old OS versions and Linux'

  s.description      = <<-DESC
  CodableWithConfiguration ported to older versions of Apple operating systems and Linux
                       DESC

  s.homepage         = 'https://github.com/tesseract-one/ContextCodable.swift'

  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/ContextCodable.swift.git', :tag => s.version.to_s }

  s.swift_version    = '5.4'
  s.module_name      = 'ContextCodable'

  base_platforms     = { :ios => '11.0', :osx => '10.13', :tvos => '11.0' }
  s.platforms        = base_platforms.merge({ :watchos => '6.0' })

  s.source_files     = 'Sources/ContextCodable/**/*.swift'
  
  s.test_spec 'Tests' do |ts|
    ts.platforms = base_platforms
    ts.source_files = 'Tests/ContextCodableTests/*.swift'
  end
end
