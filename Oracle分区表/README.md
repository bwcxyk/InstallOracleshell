# 作者简介
>- 作者：LuciferLiu，中国DBA联盟(ACDU)成员。
>- 目前从事Oracle DBA工作，曾从事 Oracle 数据库开发工作，主要服务于生产制造，汽车金融等行业。
>- 现拥有Oracle OCP，OceanBase OBCA认证，擅长Oracle数据库运维开发，备份恢复，安装迁移，Linux自动化运维脚本编写等。

![镇楼](https://img-blog.csdnimg.cn/20210703025104606.png)

# 前言
- 分区表作为Oracle三大组件之一，在Oracle数据库中，起着至关重要的作用。
>**<font color='blue'>分区表有什么优点？</font>**
>- 普通表转分区表：应用程序无感知，DML 语句无需修改即可访问分区表。
>- 高可用性：部分分区不可用不影响整个分区表使用。
>- 方便管理：可以单独对分区进行DDL操作，列入重建索引或扩展分区，不影响分区表的使用。
>- 减少OLTP系统资源争用：因为DML分布在很多段上进行操作。
>- 增强数据仓库的查询性能：可按时间进行分区查询，加速查询。

在运维开发过程中，发现有部分应用厂商在建表之初并未考虑到数据体量的问题，导致很多大表都没有建成分区表。在系统运行过程中，这些表的数据量一直在增大，当达到一定体量时，我们就需要考虑对其进行分区表转换，以提高数据库的性能。那么，如何操作呢？

# 一、介绍
- 普通表转换为分区表，Oracle给我们提供了哪些方式呢？

>- 数据泵导入
>- 子查询方式插入
>- 分区交换
>- 在线重定义
>- ALTER TABLE...MODIFY...方式（12.2之后支持）

以上几种方式中，我比较常用的是：**数据泵导入，子查询插入，在线重定义**。这三种方式的共同点都是 **需要提前创建分区表结构的中间表或者目标表。**

# 二、脚本
- 在长时间的重复性工作中，“懒癌”发作的我就想着是否能通过自动化的方式构建分区表的建表语句呢？然后我发现了 **梁敬彬大佬**的 普通表自动转化为按月分区表的脚本。

经加工和提炼，将以上脚本修改为契合自己使用的脚本：
>- 用于生成CTAS完整分区表建表语句：ctas_par.prc
>- 用于CTAS直接转换为分区表：par_tab_deal.pkg

- **par_tab_deal.pkg** 的使用方式为：

```sql
--创建日志表 PART_TAB_LOG
create table PART_TAB_LOG
(
 TAB_NAME     VARCHAR2(200),
 DEAL_MODEL   VARCHAR2(200),
 SQL_TEXT     clob,
 DEAL_TIME    DATE,
 remark       VARCHAR2(4000),
 exec_order1  number,
 exec_order2  number
);

--执行分区表转换
BEGIN
  pkg_deal_part_tab.p_main(p_tab            => 't1',
                           p_deal_flag      => 1,
                           p_parallel       => 8,
                           p_part_colum     => 'created_date',
                           p_part_nums      => 24,
                           p_tab_tablespace => 'users',
                           p_idx_tablespace => 'users');
END;

--查看日志
select DBMS_LOB.SUBSTR(sql_text,1000)||';' from part_tab_log t where tab_name='T1' order by exec_order1,exec_order2;
select sql_text||';' from part_tab_log t where tab_name='T1' order by exec_order1,exec_order2;
```
- **ctas_par.prc** 的使用方式：

```sql
--直接执行输出即可
BEGIN
  ctas_par(p_tab        => 't1',
           p_part_colum => 'created_date',
           p_part_nums  => 24,
           p_tablespace => 'users');
END;
```

# 三、应用
##  1 创建测试表T1
```sql
--删除t1表
DROP TABLE t1 PURGE;
--创建t1表
CREATE TABLE t1 (
  id           NUMBER,
  description  VARCHAR2(50),
  created_date DATE,
  CONSTRAINT t1_pk PRIMARY KEY (id)
);
--创建索引
CREATE INDEX t1_created_date_idx ON t1(created_date);
--插入数据
INSERT INTO t1
SELECT level,
       'Description for ' || level,
       ADD_MONTHS(TO_DATE('01-JAN-2017', 'DD-MON-YYYY'), -TRUNC(DBMS_RANDOM.value(1,4)-1)*12)
FROM   dual
CONNECT BY level <= 10000;
COMMIT;
```
![测试数据创建](https://img-blog.csdnimg.cn/20210703005000560.png)
## 2 创建procedure
- 执行以上脚本创建procedure：

![创建procedure](https://img-blog.csdnimg.cn/20210703005312356.png)
![有效对象](https://img-blog.csdnimg.cn/20210703005524813.png)
```sql
select  'alter  '||object_type||'   '||owner||'.'||object_name||'   compile;'
from  dba_objects t
where t.object_type='PROCEDURE'
and t.object_name='CTAS_PAR' ;
```
![确认procedure有效](https://img-blog.csdnimg.cn/20210703005711993.png)

**注意：确认procedure已成功创建。**

## 3 执行procedure
- 执行procedure生成CTAS创建分区表语句：
>- 表名：T1
>- 分区键：CREATED_DATE
>- 建立分区月数：24
>- 分区所在表空间：USERS
```sql
alter session set nls_date_format="yyyy-mm-dd hh24:mi:ss";
BEGIN
  ctas_par(p_tab        => 'T1',
           p_part_colum => 'CREATED_DATE',
           p_part_nums  => 24,
           p_tablespace => 'USERS');
END;
```
![执行结果](https://img-blog.csdnimg.cn/20210703011402930.png)
- 执行脚本如下：
```sql
--分区表获取分区列最小记录日期：2015-01-01 00:00:00
--分区表ctas创建的完整语句如下： 
create table T1
partition BY RANGE(CREATED_DATE)(
partition T1_P201501 values less than (TO_DATE(' 2015-02-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201502 values less than (TO_DATE(' 2015-03-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201503 values less than (TO_DATE(' 2015-04-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201504 values less than (TO_DATE(' 2015-05-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201505 values less than (TO_DATE(' 2015-06-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201506 values less than (TO_DATE(' 2015-07-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201507 values less than (TO_DATE(' 2015-08-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201508 values less than (TO_DATE(' 2015-09-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201509 values less than (TO_DATE(' 2015-10-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201510 values less than (TO_DATE(' 2015-11-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201511 values less than (TO_DATE(' 2015-12-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201512 values less than (TO_DATE(' 2016-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201601 values less than (TO_DATE(' 2016-02-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201602 values less than (TO_DATE(' 2016-03-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201603 values less than (TO_DATE(' 2016-04-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201604 values less than (TO_DATE(' 2016-05-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201605 values less than (TO_DATE(' 2016-06-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201606 values less than (TO_DATE(' 2016-07-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201607 values less than (TO_DATE(' 2016-08-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201608 values less than (TO_DATE(' 2016-09-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201609 values less than (TO_DATE(' 2016-10-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201610 values less than (TO_DATE(' 2016-11-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201611 values less than (TO_DATE(' 2016-12-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201612 values less than (TO_DATE(' 2017-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_MAX values less than (maxvalue) tablespace USERS)
             nologging
             parallel 4
             enable row movement
             tablespace USERS
             as select /*+parallel(t,8)*/ * from T1_01 t where 1 = 2;
--附加日志和取消并行
alter table T1 logging;
alter table T1 noparallel; 
```

**<font color='blue'>如果只是需要分区表的建表语句，这里已经可以很简单的拼接出来：</font>**

```sql
create table T1
(
  id           NUMBER,
  description  VARCHAR2(50),
  created_date DATE
)
partition BY RANGE(CREATED_DATE)(
partition T1_P201501 values less than (TO_DATE(' 2015-02-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201502 values less than (TO_DATE(' 2015-03-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201503 values less than (TO_DATE(' 2015-04-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201504 values less than (TO_DATE(' 2015-05-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201505 values less than (TO_DATE(' 2015-06-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201506 values less than (TO_DATE(' 2015-07-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201507 values less than (TO_DATE(' 2015-08-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201508 values less than (TO_DATE(' 2015-09-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201509 values less than (TO_DATE(' 2015-10-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201510 values less than (TO_DATE(' 2015-11-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201511 values less than (TO_DATE(' 2015-12-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201512 values less than (TO_DATE(' 2016-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201601 values less than (TO_DATE(' 2016-02-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201602 values less than (TO_DATE(' 2016-03-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201603 values less than (TO_DATE(' 2016-04-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201604 values less than (TO_DATE(' 2016-05-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201605 values less than (TO_DATE(' 2016-06-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201606 values less than (TO_DATE(' 2016-07-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201607 values less than (TO_DATE(' 2016-08-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201608 values less than (TO_DATE(' 2016-09-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201609 values less than (TO_DATE(' 2016-10-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201610 values less than (TO_DATE(' 2016-11-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201611 values less than (TO_DATE(' 2016-12-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_P201612 values less than (TO_DATE(' 2017-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) tablespace USERS,
partition T1_MAX values less than (maxvalue) tablespace USERS)
ENABLE ROW MOVEMENT
TABLESPACE USERS;
```

## 4 CTAS创建分区表
- 实际执行前，需要先将原表T1进行rename。

```sql
alter table lucifer.T1 RENAME TO T1_01;
```
![rename原表T1](https://img-blog.csdnimg.cn/20210703011725486.png)

**注意：如需创建分区表结构，无需修改以上脚本；如需直接创建分区表包含数据，需要将 `where 1 = 2` 修改为 `where 1 = 1`。**

- 确保当前表T1已经rename为T1_01，执行CTAS创建分区表：

![CTAS创建分区表](https://img-blog.csdnimg.cn/20210703014408714.png)
- 查看分区表结构：

![分区表结构](https://img-blog.csdnimg.cn/20210703012637658.png)
注意：由于CTAS不会继承 **注释，默认值**，因此需要手动比对是否缺失。

```sql
COMMENT ON TABLE T1 IS '';
COMMENT ON COLUMN T1.ID IS '';
COMMENT ON COLUMN T1.CREATED_DATE IS '';
COMMENT ON COLUMN T1.DESCRIPTION IS '';
```

- 重命名原表的索引和约束

```sql
--重命名索引
ALTER INDEX T1_CREATED_DATE_IDX RENAME TO T1_CREATED_DATE_IDX_01;
ALTER INDEX T1_PK RENAME TO T1_PK_01;
--重命名唯一约束
ALTER TABLE T1_01 RENAME CONSTRAINT T1_PK TO T1_PK_01;
```
![重命名原表索引](https://img-blog.csdnimg.cn/20210703015525533.png)
- 分区表新建本地索引

```sql
create index T1_CREATED_DATE_IDX on T1 (CREATED_DATE) tablespace users;
alter table T1 add constraint T1_PK primary key (ID) using index  tablespace users;
```
![创建本地索引](https://img-blog.csdnimg.cn/20210703020116628.png)
- 查询分区表

通过以下查询可以发现，数据已被按月分到对应分区下：

```sql
SELECT COUNT(1) FROM t1;
SELECT COUNT(1) FROM t1 PARTITION(T1_P201501);
SELECT COUNT(1) FROM t1 PARTITION(T1_P201601);
SELECT COUNT(1) FROM t1 PARTITION(T1_MAX);
```
![分区表查询](https://img-blog.csdnimg.cn/20210703021332520.png)

**至此，脚本已经介绍完毕。**

---
本次分享到此结束啦~

如果觉得文章对你有帮助，请`star`一下，一键四连支持，你的支持就是我创作最大的动力。

技术交流可以 关注公众号：**Lucifer三思而后行**

![Lucifer三思而后行](https://img-blog.csdnimg.cn/20210702105616339.jpg)