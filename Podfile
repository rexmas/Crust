platform :ios, '10.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'

target 'Crust' do
  pod 'JSONValueRX', '~> 7.0.0'

  target 'CrustTests' do
    inherit! :complete
  end

  target 'RealmCrustTests' do
    inherit! :complete
    pod 'RealmSwift'
  end
end

