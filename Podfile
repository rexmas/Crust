# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
use_frameworks!

target 'Crust' do
  pod 'JSONValueRX', '~> 2.0.0'

  target 'CrustTests' do
    inherit! :complete
  end

  target 'RealmCrustTests' do
    inherit! :complete
    pod 'RealmSwift'
  end
end

