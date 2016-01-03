#
# Be sure to run `pod lib lint Crust.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Crust"
  s.version          = "0.0.1"
  s.summary          = "Flexible Swift JSON object mapping with support for Realm, etc."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
  A flexible Swift framework for converting classes and structs to and from JSON with support for storage solutions such as Realm.
                       DESC

  s.homepage         = "https://github.com/rexmas/Crust"
  s.license          = 'MIT'
  s.author           = { "rexmas" => "rex.fenley@gmail.com" }
  s.source           = { :git => "https://github.com/rexmas/Crust.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.dependency 'JSONValueRX'
  s.source_files = 'Crust/**/*.swift'
  s.resource_bundles = {
  }

end
