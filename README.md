# 前言
作为IT人，相信大家多多少少都接触使用过Oracle数据库，但是很少有人安装过Oracle数据库，因为这种活一般都是DBA干的，比如博主😬。那么，如果自己想安装一套Oracle数据库进行测试，如何安装呢？

# 一、介绍
俗说得好：**<font color='#f47920'>"懒人"推动世界的发展。</font>** 既然能用脚本解决的事情，为什么还要那么麻烦，干就完事儿了。

## 1 功能介绍
- **本脚本有哪些功能？支持哪些版本？有哪些参数？不急，功能太多，待我慢慢道来：**

> - 支持Oracle版本：11GR2、12C、18C、19C
>- 支持Linux版本(x86_64)：6、7、8
>- 支持安装模式：单机，单机集群，RAC
>- 帮助命令查看参数
>- 安装日志记录
>- 配置操作系统
>- 安装Grid软件
>- 安装Oracle软件
>- 安装PSU&&RU补丁
>- 创建数据库

## 2 参数介绍
- **本脚本通过参数来预配置脚本命令，可通过帮助命令来查看有哪些参数：**

> 执行 `./OracleShellInstall --help` 可以查看参数：

```bash
-i,	--PUBLICIP				PUBLICIP NETWORK ADDRESS
-n,	--HOSTNAME				HOSTNAME(orcl)
-o,	--ORACLE_SID				ORACLE_SID(orcl)
-c,	--ISCDB					IS CDB OR NOT(TRUE|FALSE)
-pb,	--PDBNAME				PDBNAME
-op,	--ORAPASSWD				ORACLE USER PASSWORD(oracle)
-b,	--ENV_BASE_DIR			        ORACLE BASE DIR(/u01/app)
-s,	--CHARACTERSET			        ORACLE CHARACTERSET(ZHS16GBK|AL32UTF8)
-rs,	--ROOTPASSWD				ROOT USER PASSWORD
-gp,	--GRIDPASSWD				GRID USER PASSWORD(oracle)
-pb1,	--RAC1PUBLICIP				RAC NODE ONE PUBLIC IP
-pb2,	--RAC2PUBLICIP				RAC NODE SECONED PUBLIC IP
-vi1,	--RAC1VIP				RAC NODE ONE VIRTUAL IP
-vi2,	--RAC2VIP				RAC NODE SECOND VIRTUAL IP
-pi1,	--RAC1PRIVIP				RAC NODE ONE PRIVATE IP
-pi2,	--RAC2PRIVIP				RAC NODE SECOND PRIVATE IP
-pi3,	--RAC1PRIVIP1				RAC NODE ONE PRIVATE IP
-pi4,	--RAC2PRIVIP1				RAC NODE SECOND PRIVATE IP
-puf,	--RACPUBLICFCNAME	                RAC PUBLIC FC NAME
-prf,	--RACPRIVFCNAME				RAC PRIVATE FC NAME
-prf1,	--RACPRIVFCNAME1			RAC PRIVATE FC NAME
-si,	--RACSCANIP				RAC SCAN IP
-dn,	--ASMDATANAME				RAC ASM DATADISKGROUP NAME(DATA)
-on,	--ASMOCRNAME				RAC ASM OCRDISKGROUP NAME(OCR)
-dd,	--DATA_BASEDISK				RAC DATADISK DISKNAME
-od,	--OCRP_BASEDISK				RAC OCRDISK DISKNAME
-or,	--OCRREDUN				RAC OCR REDUNDANCY(EXTERNAL|NORMAL|HIGH)
-dr,	--DATAREDUN				RAC DATA REDUNDANCY(EXTERNAL|NORMAL|HIGH)
-tsi,   --TIMESERVERIP                          RAC TIME SERVER IP
-txh    --TuXingHua                             Tu Xing Hua Install
-udev   --UDEV                                  Whether Auto Set UDEV
-dns    --DNS                                   RAC CONFIGURE DNS(Y|N)
-dnss   --DNSSERVER                             RAC CONFIGURE DNSSERVER LOCAL(Y|N)
-dnsn   --DNSNAME                               RAC DNSNAME(orcl.com)
-dnsi   --DNSIP                                 RAC DNS IP
-m,	--ONLYCONFIGOS				ONLY CONFIG SYSTEM PARAMETER(Y|N)
-g,	--ONLYINSTALLGRID 			ONLY INSTALL GRID SOFTWARE(Y|N)
-w,	--ONLYINSTALLORACLE 		        ONLY INSTALL ORACLE SOFTWARE(Y|N)
-ocd,	--ONLYCREATEDB		                ONLY CREATE DATABASE(Y|N)
-gpa,	--GRID RELEASE UPDATE		        GRID RELEASE UPDATE(32072711)
-opa,	--ORACLE RELEASE UPDATE		        ORACLE RELEASE UPDATE(32072711)
```
**<font color='blue'>看到上面的参数，是否感觉参数太多，但是这些参数都有用，容我一个个慢慢道来：</font>**
- **`-i`  全称 PUBLICIP：当前主机用于访问的IP，<font color='red'>必填参数</font>。**

> 使用方式：`-i 10.211.55.100`
- **`-n` 全称 HOSTNAME：当前主机的主机名，默认值为 orcl。**

> 使用方式：`-n orcl`
> 如果选择rac模式，节点1、2主机名自动取为：orcl01、orcl02。
![rac主机名](https://img-blog.csdnimg.cn/20210614005440752.png)
- **`-o` 全称 ORACLE_SID：Oracle实例名称，默认值为 orcl。**

> 使用方式：`-o orcl`

- **`-c` 全称 ISCDB：判断是否为CDB模式，11GR2不支持该参数，默认值为FALSE。**

> 使用方式：`-c TRUE`

- **`-pb` 全称 PDBNAME：创建PDB的名称，11GR2不支持该参数。**

> 使用方式：`-pb pdb01`

- **`-op` 全称 ORAPASSWD：oracle用户的密码，默认值为oracle。**

> 使用方式：`-op oracle`

- **`-b` 全称 ENV_BASE_DIR：Oracle基础安装目录，默认值为/u01/app。**

> 使用方式：`-b /u01/app`

- **`-s` 全称 CHARACTERSET：Oracle数据库字符集，默认值为AL32UTF8。**

> 使用方式：`-s AL32UTF8`

**<font color='blue'>以下为RAC模式安装的参数：</font>**

- **`-rs` 全称 ROOTPASSWD：root用户的密码，默认值为oracle。**

> 使用方式：`-rs oracle`

- **`-gp` 全称 GRIDPASSWD：grid用户的密码，默认值为oracle。**

> 使用方式：`-gp oracle`

- **`-pb1` 全称 RAC1PUBLICIP：节点一的主机访问IP，<font color='red'>必填参数</font>。**

> 使用方式：`-pb1 10.211.55.100`

- **`-pb2` 全称 RAC2PUBLICIP：节点二的主机访问IP，<font color='red'>必填参数</font>。**

> 使用方式：`-pb2 10.211.55.101`

- **`-vi1` 全称 RAC1VIP：节点一的主机虚拟IP，<font color='red'>必填参数</font>，与主机访问IP网段必须相同。**

> 使用方式：`-vi1 10.211.55.102`

- **`-vi2` 全称 RAC2VIP：节点二的主机虚拟IP，<font color='red'>必填参数</font> ，与主机访问IP网段必须相同。**

> 使用方式：`-vi2 10.211.55.103`

- **`-pi1` 全称 ：RAC1PRIVIP，节点一的主机私有IP，<font color='red'>必填参数</font> ，可凭借喜好进行自定义。**

> 使用方式：`-pi1 10.10.1.1`

- **`-pi2` 全称 ：RAC2PRIVIP，节点二的主机私有IP，<font color='red'>必填参数</font>，可凭借喜好进行自定义。**

> 使用方式：`-pi2 10.10.1.2`

- **`-pi3` 全称 ：RAC1PRIVIP1，节点一的第二个主机私有IP，<font color='blue'>可选参数</font> ，可凭借喜好进行自定义。**

> 使用方式：`-pi3 1.1.1.1`

- **`-pi4` 全称 ：RAC2PRIVIP1，节点二的第二个主机私有IP，<font color='blue'>可选参数</font> ，可凭借喜好进行自定义。**

> 使用方式：`-pi4 1.1.1.2`

- **`-puf` 全称 ：RACPUBLICFCNAME，主机的访问IP对应的网卡名称，<font color='red'>必填参数</font> ，节点1，2必须名称一致。**

> 使用方式：`-puf eth0`

- **`-prf` 全称 RACPRIVFCNAME：主机的私有IP对应的网卡名称，<font color='red'>必填参数</font> ，节点1，2必须名称一致。**

> 使用方式：`-prf eth1`

- **`-prf1` 全称 RACPRIVFCNAME1：主机的第二私有IP对应的网卡名称，<font color='blue'>可选参数</font> ，节点1，2必须名称一致。**

> 使用方式：`-prf1 eth2`

- **`-si` 全称 RACSCANIP：主机的SCANIP，<font color='red'>必填参数</font> ，与主机访问IP网段必须相同。当配置DNS解析时，最多可支持填写3个IP，通过逗号隔开。**

> 使用方式：`-si 10.211.55.104,10.211.55.105,10.211.55.106`

- **`-dn` 全称 ASMDATANAME：ASM数据盘名称，默认值为DATA。**

> 使用方式：`-dn DATA`

- **`-on` 全称 ASMOCRNAME：ASM裁决盘名称，默认值为OCR。**

> 使用方式：`-on OCR`

- **`-dd` 全称 DATA_BASEDISK：数据盘对应的磁盘名称，<font color='red'>必填参数</font> 。支持多块磁盘填写，用逗号隔开。**

> 使用方式：`-dd /dev/sdb,/dev/sdc,/dev/sdd`

- **`-od` 全称 OCR_BASEDISK：裁决盘对应的磁盘名称，<font color='red'>必填参数</font> 。支持多块磁盘填写，用逗号隔开。**

> 使用方式：`-od /dev/sde,/dev/sdf`

- **`-or` 全称 OCRREDUN：裁决盘的冗余选项，默认值为EXTERNAL。<font color='blue'>冗余选项EXTERNAL、NORMAL、HIGH对应磁盘最小数量为1、3、5。</font>**

> 使用方式：`-or EXTERNAL`

- **`-dr` 全称 OCRREDUN：裁决盘的冗余选项，默认值为EXTERNAL。<font color='blue'>冗余选项EXTERNAL、NORMAL、HIGH对应磁盘最小数量为1、2、3。</font>**

> 使用方式：`-dr EXTERNAL`

- **`-tsi` 全称 TIMESERVERIP：时间同步服务器IP，<font color='blue'>可选参数</font> ，根据实际情况进行填写。**

> 使用方式：`-tsi 10.211.55.200`

- **`-txh` 全称 TuXingHua：图形化界面安装，默认值为N。选择Y后将安装图形化界面所需依赖。**

> 使用方式：`-txh Y`

- **`-udev` 全称 UDEV：自动配置multipath+UDEV绑盘，默认值为Y。**

> 使用方式：`-udev Y`

**<font color='blue'>以下参数为配置DNS解析：</font>**

- **`-dns` 全称 DNS：配置DNS解析，默认值为N。**

> 使用方式：`-dns N`

- **`-dnss` 全称 DNSSERVER：当前主机配置为DNS服务器，默认值为N。前提是 `-dns Y` 才生效。**

> 使用方式：`-dnss N`

- **`-dnsn` 全称 DNSNAME：DNS服务器的解析名称，前提是 `-dns Y` 才生效。**

> 使用方式：`-dnsn orcl.com`

- **`-dnsi` 全称 DNSIP：DNS服务器的IP，前提是 `-dns Y` 才生效。**

> 使用方式：`-dnsi 10.211.55.200`

- **`-m` 全称 ONLYCONFIGOS：仅配置操作系统参数，默认值为N。值为Y时，脚本只执行到操作系统配置完成就结束，不会进行安装，通常可用于图形化安装的初始化。**

> 使用方式：`-m Y`

- **`-g` 全称 ONLYINSTALLGRID：仅安装Grid软件，默认值为N。**

> 使用方式：`-g Y`

- **`-w` 全称 ONLYINSTALLORACLE：仅安装Oracle软件，默认值为N。**

> 使用方式：`-w Y`

- **`-ocd` 全称 ONLYCREATEDB：仅创建Oracle数据库实例，默认值为N。**

> 使用方式：`-ocd Y`

- **`-gpa` 全称 GRID RELEASE UPDATE：Grid软件的PSU或者RU补丁的补丁号。**

> 使用方式：`-gpa 32072711`

- **`-opa` 全称 ORACLE RELEASE UPDATE：Oracle软件的PSU或者RU补丁的补丁号。**

> 使用方式：`-opa 32072711`

**<font color='blue'>通过以上的参数介绍，相信大家对脚本的功能已经一览无余了，可以说是非常强大。是不是已经心动不如行动，想要尝试下进行安装了呢？接下来将介绍如何使用脚本。</font>**

# 二、使用
既然已经了解脚本的功能和参数，接下来就是了解如何使用脚本。
![脚本流程图](https://img-blog.csdnimg.cn/20210603100942949.png)
**直接上命令：** `./OracleShellInstall.sh -i 10.211.55.100`

**Notes：** 最便捷安装方式，默认参数不设置，只需加上主机IP，即可一键安装Oracle数据库。

## 1 创建软件目录，例如：/soft
```
mkdir /soft
```
## 2 挂载Linux安装镜像
```bash
## 1.通过cdrom挂载
mount /dev/cdrom /mnt
## 2.通过安装镜像源挂载
mount -o loop /soft/rhel-server-7.9-x86_64-dvd.iso /mnt
```
![镜像挂载](https://img-blog.csdnimg.cn/20210603104047853.png)
## 3 上传安装介质和脚本到软件目录
```bash
## 一键安装shell脚本
140K	OracleShellInstall.sh
## oracle 11GR2官方安装包
1.3G	p13390677_112040_Linux-x86-64_1of7.zip
1.1G	p13390677_112040_Linux-x86-64_2of7.zip
## 授权脚本执行权限
chmod +x OracleShellInstall.sh
```
![安装介质](https://img-blog.csdnimg.cn/20210603104132703.png)
## 4 执行安装：
```
./OracleShellInstall.sh -i 10.211.55.100
```
![执行安装](https://img-blog.csdnimg.cn/20210603104254309.png)
**等待5-10分钟左右，安装成功。**
![安装成功提示](https://img-blog.csdnimg.cn/2021060310483362.png)![数据库信息](https://img-blog.csdnimg.cn/20210603105049292.png)
## 5 数据库连接使用
不知道如何安装PLSQL的同学，可以参考：[零基础如何玩转PL/SQL DEVELOPER？](https://luciferliu.blog.csdn.net/article/details/117913049)
- 创建连接用户：

  ![创建连接用户](https://img-blog.csdnimg.cn/20210603110123160.png)

- plsql连接：

  ![plsql连接](https://img-blog.csdnimg.cn/20210603110313601.png)
  ![测试数据](https://img-blog.csdnimg.cn/2021060311050120.png)

**<font color='blue'>通过如上简单的使用教程，轻松安装Oracle数据库，大大缩减人工和时间成本。</font>**

# 三、示例
## 1 单实例安装
```bash
./OracleShellInstall.sh -i 10.211.55.100 `#Public ip`\
-n orcl `# hostname`\
-o orcl `# oraclesid`\
-op oracle `# oracle user password`\
-b /u01/app `# install basedir`\
-s AL32UTF8 `# characterset`\
-opa 31537677 `# oracle psu number`
```

## 2 RAC安装
```bash
./OracleShellInstall.sh -i 10.211.55.100 `#Public ip`\
-n rac `# hostname`\
-rs oracle `# root password`\
-op oracle `# oracle password`\
-gp oracle `# grid password`\
-b /u01/app `# install basedir`\
-o orcl `# oraclesid`\
-s AL32UTF8 `# characterset`\
-pb1 10.211.55.100 -pb2 10.211.55.101 `# node public ip`\
-vi1 10.211.55.102 -vi2 10.211.55.103 `# node virtual ip`\
-pi1 10.10.1.1 -pi2 10.10.1.2 `# node private ip`\
-puf eth0 -prf eth1 `# network fcname`\
-si 10.211.55.105 `# scan ip`\
-dd /dev/sde,/dev/sdf `# asm data disk`\
-od /dev/sdb,/dev/sdc,/dev/sdd `# asm ocr disk`\
-or EXTERNAL `# asm ocr redundancy`\
-dr EXTERNAL `# asm data redundancy`\
-on OCR `# asm ocr diskgroupname`\
-dn DATA `# asm data diskgroupname`\
-gpa 32580003 `# GRID PATCH`
```

**<font color='blue'>如果能够合理使用该脚本，可以在Linux系统轻松安装Oracle数据库，释放双手，养生敲代码不是梦！！！</font>**

<font color='red'>更多更详细的脚本使用方式可以订阅专栏：</font> [Oracle一键安装脚本](https://blog.csdn.net/m0_50546016/category_11127389.html)
> - [15分钟！一键部署Oracle 12CR2单机CDB+PDB](https://blog.csdn.net/m0_50546016/article/details/116521750)
>- [20分钟！一键部署Oracle 18C单机CDB+PDB](https://blog.csdn.net/m0_50546016/article/details/116522953)
>- [25分钟！一键部署Oracle 11GR2 HA 单机集群](https://blog.csdn.net/m0_50546016/article/details/116547743)
>- [30分钟！一键部署Oracle 19C单机CDB+PDB](https://blog.csdn.net/m0_50546016/article/details/116524049)
>- [1.5小时！一键部署Oracle 11GR2 RAC 集群](https://blog.csdn.net/m0_50546016/article/details/116549125)

---
本次分享到此结束啦~

如果觉得文章对你有帮助，请`star`一下，你的支持就是我创作最大的动力。

技术交流可以**关注公众号：Lucifer三思而后行**

![Lucifer三思而后行](https://img-blog.csdnimg.cn/20210702105616339.jpg)