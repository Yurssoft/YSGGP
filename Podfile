platform :ios, '10.0'
use_frameworks!
target 'QuickFile' do
    pod 'SwiftMessages'
    pod 'M13ProgressSuite'
    pod 'Firebase/Core'
    pod 'Firebase/Database'
    pod 'Firebase/Auth'
    pod 'Firebase/Crash'
    pod 'Firebase/Performance'
    pod 'Firebase/Messaging'
    pod 'DownloadButton'
    pod 'GoogleSignIn'
    pod 'KeychainAccess'
    pod 'ReachabilitySwift'
    pod 'MarqueeLabel/Swift'
    pod 'DZNEmptyDataSet'
    pod 'NSLogger/Swift'
    pod 'Reqres'
    pod 'Reflection'
    pod 'SwiftyTimer'
    pod 'SwiftLint'
    pod 'RazzleDazzle'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
