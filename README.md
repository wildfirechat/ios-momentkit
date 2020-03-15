# ios-momentkit
iOS 朋友圈UI组件库

## 朋友圈组成
朋友圈后端需要IM专业版，IM专业版需要使用mongoDB。

朋友圈前端只包括android和iOS端，web和pc端不支持；前端分为kit和client两个SDK，kit是UI开源库，client是闭源功能库；client库是收费项目，闭源且绑定域名，需要购买才能使用。

## 编译
依赖ios-momentclient，WFChatUIKit和WFChatClient。先编译ios-chat项目，编译完成之后，在ios-chat/wfchat/Frameworks目录下找到的WFChatUIKit.framework和WFChatClient.framework拷贝到本项目Frameworks目录下(如果本地没有此目录就新建一个)。然后购买或申请试用momentclient库，同样放到Frameworks目录下。然后分别编译模拟器和真机，生成的kit sdk包在bin目录下。


## 使用
生成的sdk需要集成到ios-chat项目使用，拷贝kit sdk和client sdk到ios-chat/wfchat/WildFireChat/Moments，替换掉已经存在的两个占位的空库，运行测试即可。

由于都是动态库，所以导入其它项目时需要embed方式，另外打包上架时需要去除x64架构，去除方法可以参考ios-chat/wfchat/removex86.sh脚本

## Base项目
本工程是基于[GSD_WeiXin](https://github.com/gsdios/GSD_WeiXin)二次开发而成，感谢原作者的贡献

## License
本工程为MIT协议
