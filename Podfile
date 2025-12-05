# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'ViewPagerDemo' do
  use_frameworks!
  pod 'MJRefresh'
end

post_install do |installer|
  # 设置 Pods 项目
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  
  # 设置主项目
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
end
