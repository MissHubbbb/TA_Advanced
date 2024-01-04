# TA_Advanced
## PBR Part
第一部分是PBR的材质实现，主要参考的是LearnOpenGL教程中PBR部分，还有知乎一位大佬的文章，下面放上链接。
 - LearnOpenGL——PBR：https://learnopengl-cn.github.io/07%20PBR/01%20Theory/
 - 知乎——Unity的URP实现PBR： https://zhuanlan.zhihu.com/p/517120906

下面放上展示效果图，图片分上下两个模型。
 - 上面的模型是unity默认的URP Lit材质。Lit材质没有附带粗糙度贴图选项，只有一个smooth滑条，我适当调节了一下。
 - 下面的模型则是个人编写的PBR材质。

![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/PBR_0.png)
![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/PBR_1.png)
![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/PBR_2.png)
![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/PBR_3.png)

## NPR Part
第二部分接着实现了NPR效果，使用的是罪恶装备的RAM人物模型，网上的模型五花八门的，一开始找的一个在后面的法线平滑处理的时候出现了问题，所以后面找的这个模型就不带披风，应该也不影响。
本来是想实现原神的NPR渲染的，但是找到的资源里面的贴图不全，索性选择罪恶装备先了解一下大概，后面有机会再实现米哈游那一套。
虽说也是到处拾人牙慧，但勉强算做出来了。照例放上参考链接：
 - TA技术美术-罪恶装备角色还原：https://zhuanlan.zhihu.com/p/493802718
 - 从《罪恶装备Xrd》看卡通渲染游戏中使用的技术——《角色渲染篇》：https://zhuanlan.zhihu.com/p/508826073
 - 渲染示例：罪恶装备(NPR-Unity)：https://zhuanlan.zhihu.com/p/669240605
 - 【01】从零开始的卡通渲染-描边篇：https://zhuanlan.zhihu.com/p/109101851

下面放上展示效果图：
 - 整体效果：
   ![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/NPR_3.png)
 - alpha test：
   ![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/NPR_2.png)
 - 法线平滑(解决硬表面描边断裂的问题)：
   ![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/NPR_1.png)
 - 边缘光(rim)和内描线:
   ![image](https://github.com/MissHubbbb/TA_Advanced/blob/main/CoverImage/NPR_0.png)

其他的还是有一些没实现的地方，比如说面部阴影，原神常用的sdf的方案，但是罪恶装备没有专门给人物模型的面部阴影制作贴图。他们用的好像是掰法线，但是我建模软件用的不太熟，后面得在研究研究。
还有就是人物裤子那个地方的阴影太重，应该是在处理哪张贴图没处理到，等组会忙完后再回头看看吧。
