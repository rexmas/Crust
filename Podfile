# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
use_frameworks!

target 'Crust' do
  pod 'JSONValueRX', '~> 4.0.2'

  target 'CrustTests' do
    inherit! :complete
  end

  target 'RealmCrustTests' do
    inherit! :complete
    pod 'RealmSwift'
  end
end

