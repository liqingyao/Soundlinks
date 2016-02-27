# Workflow

##### 1. 使用 Bitbucket 的 Soundlinks 工程（包含源程序）修改 source code

- source 查找路径为本地目录

`s.source = { :git => "/Users/liqingyao/Documents/Bitbucket/Soundlinks", :tag => s.version }`

- commit

```ruby
git add .
git commit -a -m 'v0.1.0'
git tag -a 0.1.0 -m 'v0.1.0'
```

- 验证 podspec 是否符合 pod 要求

`pod lib lint --verbose`

- 打包导出 .a 静态库

`pod package Soundlinks.podspec --library --force`


##### 2. 拷贝新的 .a 静态库到 Github 的 Soundlinks 工程 （用来正式发布新版本和示例程序）

- source 查找路径为 github 对应地址

`s.source = { :git => "https:/github.com/liqingyao/Soundlinks/git", :tag => s.version }`

- 把新的 .a 静态库替换原来的

- 更新 README 文件

- 更新 Example 及注释

- 提交源代码到 Github commit & push & push --tags

- 验证 podspec 是否符合 pod 要求

`pod spec lint Soundlinks.podspec`

- 提交 podspec 到 CocoaPods

`pod trunk push Soundlinks.podspec`
