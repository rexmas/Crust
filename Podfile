# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
use_frameworks!

target 'Crust' do
  pod 'JSONValueRX'

  target 'CrustTests' do
    inherit! :complete
  end

  target 'RealmCrust' do
    inherit! :complete
    pod 'RealmSwift'

    target 'RealmCrustTests' do
      inherit! :complete
    end
  end
end

