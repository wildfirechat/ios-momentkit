## 野火IM解决方案

野火IM是专业级即时通讯和实时音视频整体解决方案，由北京野火无限网络科技有限公司维护和支持。

主要特性有：私有部署安全可靠，性能强大，功能齐全，全平台支持，开源率高，部署运维简单，二次开发友好，方便与第三方系统对接或者嵌入现有系统中。详细情况请参考[在线文档](https://docs.wildfirechat.cn)。

主要包括一下项目：

| [GitHub仓库地址(主站)](https://github.com/wildfirechat)      | [码云仓库地址(镜像)](https://gitee.com/wfchat)        | 说明                                                                                      | 备注                                           |
| ------------------------------------------------------------ | ----------------------------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------- |
| [android-chat](https://github.com/wildfirechat/android-chat) | [android-chat](https://gitee.com/wfchat/android-chat) | 野火IM Android SDK源码和App源码                                                           | 可以很方便地进行二次开发，或集成到现有应用当中 |
| [ios-chat](https://github.com/wildfirechat/ios-chat)         | [ios-chat](https://gitee.com/wfchat/ios-chat)         | 野火IM iOS SDK源码和App源码                                                               | 可以很方便地进行二次开发，或集成到现有应用当中 |
| [pc-chat](https://github.com/wildfirechat/pc-chat)           | [pc-chat](https://gitee.com/wfchat/pc-chat)           | 基于[Electron](https://electronjs.org/)开发的PC平台应用                                   |                                                |
| [web-chat](https://github.com/wildfirechat/web-chat)         | [web-chat](https://gitee.com/wfchat/web-chat)         | Web平台的Demo, [体验地址](http://web.wildfirechat.cn)                                     |                                                |
| [wx-chat](https://github.com/wildfirechat/wx-chat)           | [wx-chat](https://gitee.com/wfchat/wx-chat)           | 微信小程序平台的Demo                                                                      |                                                |
| [server](https://github.com/wildfirechat/server)             | [server](https://gitee.com/wfchat/server)             | IM server                                                                                 |                                                |
| [app server](https://github.com/wildfirechat/app_server)     | [app server](https://gitee.com/wfchat/app_server)     | 应用服务端                                                                                |                                                |
| [robot_server](https://github.com/wildfirechat/robot_server) | [robot_server](https://gitee.com/wfchat/robot_server) | 机器人服务端                                                                              |                                                |
| [push_server](https://github.com/wildfirechat/push_server)   | [push_server](https://gitee.com/wfchat/push_server)   | 推送服务器                                                                                |                                                |
| [docs](https://github.com/wildfirechat/docs)                 | [docs](https://gitee.com/wfchat/docs)                 | 野火IM相关文档，包含设计、概念、开发、使用说明，[在线查看](https://docs.wildfirechat.cn/) |                                                |  |


iOS 朋友圈UI组件库

## 朋友圈组成
朋友圈后端需要IM专业版，IM专业版需要使用mongoDB。

朋友圈前端只包括android和iOS端，web和pc端不支持；前端分为kit和client两个SDK，kit是本项目，为UI开源库，client是闭源功能库；client库是收费项目，闭源且绑定域名，需要购买才能使用。

## 预览
Client SDK功能齐全，UIKit开源可以进一步定制：

首页
![预览1](http://static.wildfirechat.cn/ios-moment1.png)

发送界面
![预览2](http://static.wildfirechat.cn/ios-moment2.png)

消息界面
![预览3](http://static.wildfirechat.cn/ios-moment3.png)

详情界面
![预览4](http://static.wildfirechat.cn/ios-moment4.png)

设置界面
![预览5](http://static.wildfirechat.cn/ios-moment5.png)

## 编译
命令行下执行命令
```
sh build.sh WFMomentUIKit
```
编译成功后，会生成SDK在项目的bin目录下。


## 使用
生成的sdk需要集成到[ios-chat](https://github.com/wildfirechat/ios-chat)项目使用，拷贝kit sdk和client sdk到```ios-chat/wfchat/Frameworks```，并添加依赖。

由于都是动态库，所以导入其它项目时需要embed方式。

## Base项目
本工程是基于[GSD_WeiXin](https://github.com/gsdios/GSD_WeiXin)二次开发而成，感谢原作者的贡献

## License
本工程为MIT协议
