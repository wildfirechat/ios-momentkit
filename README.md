# ios-momentkit
iOS 朋友圈UI组件库

## 朋友圈组成
朋友圈后端需要IM专业版，IM专业版需要使用mongoDB。

朋友圈前端只包括android和iOS端，web和pc端不支持；前端分为kit和client两个SDK，kit是本项目，为UI开源库，client是闭源功能库；client库是收费项目，闭源且绑定域名，需要购买才能使用。

## 预览
Client SDK功能齐全，UIKit开源可以进一步定制：

首页
![预览1](https://static.wildfirechat.cn/ios-moment1.png)

发送界面
![预览2](https://static.wildfirechat.cn/ios-moment2.png)

消息界面
![预览3](https://static.wildfirechat.cn/ios-moment3.png)

详情界面
![预览4](https://static.wildfirechat.cn/ios-moment4.png)

设置界面
![预览5](https://static.wildfirechat.cn/ios-moment5.png)

## 编译
依赖```momentclient```，```WFChatUIKit```和```WFChatClient```。先编译[ios-chat](https://github.com/wildfirechat/ios-chat)项目，编译完成之后，在```ios-chat/wfchat/Frameworks```目录下找到的W```FChatUIKit.framework```和```WFChatClient.framework```拷贝到本项目```Frameworks```目录下(如果本地没有此目录就新建一个)。然后购买或申请试用```momentclient```库，同样放到```Frameworks```目录下。然后分别编译模拟器和真机，生成的kit sdk包在bin目录下。


## 使用
生成的sdk需要集成到[ios-chat](https://github.com/wildfirechat/ios-chat)项目使用，拷贝kit sdk和client sdk到```ios-chat/wfchat/WildFireChat/Moments```，替换掉已经存在的两个占位的空库，运行测试即可。

由于都是动态库，所以导入其它项目时需要embed方式，另外打包上架时需要去除x64架构，去除方法可以参考```ios-chat/wfchat/removex86.sh```脚本

## Base项目
本工程是基于[GSD_WeiXin](https://github.com/gsdios/GSD_WeiXin)二次开发而成，感谢原作者的贡献

## License
本工程为MIT协议
