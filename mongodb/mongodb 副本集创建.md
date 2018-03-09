# mongodb 副本集创建

## 配置文件

```shell
# 端口配置
net:
  port: 22303
  bindIp: 192.168.31.91

# 是否在后台运行
processManagement:
  fork: true

# 副本集名称，同一个副本集使用同一个名称
replication:
  replSetName: ccjhRepl1

# 数据存储地址
storage:
  dbPath: /home/gamemirror/repl/ccjhRepl/share3/data

# 日志配置
systemLog:
  destination: file
  logAppend: true
  path: /home/gamemirror/repl/ccjhRepl/share3/log/ccjhMongod.log
```

## 初始化 副本集

```shell
gamemirror@GameMirror ~/r/ccjhRepl> mongo --host 192.168.31.91 --port 22101
MongoDB shell version v3.6.1
connecting to: mongodb://192.168.31.91:22101/
MongoDB server version: 3.6.1
MongoDB Enterprise > use admin
# 定义副本集配置文件
MongoDB Enterprise > config={"_id":"ccjhRepl1","members":[{"_id":0,"host":"192.168.31.91:22101"},{"_id":1,"host":"192.168.31.91:22202"},{"_id":2,"host":"192.168.31.91:22303"}]}
# 执行后的结果
{
	"_id" : "ccjhRepl1",
	"members" : [
		{
			"_id" : 0,
			"host" : "192.168.31.91:22101"
		},
		{
			"_id" : 1,
			"host" : "192.168.31.91:22202"
		},
		{
			"_id" : 2,
			"host" : "192.168.31.91:22303"
		}
	]
}
# 初始化配置
MongoDB Enterprise > rs.initiate(config);
{
	"ok" : 1,
	"operationTime" : Timestamp(1520404248, 1),
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520404248, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
# 获取配置文件
MongoDB Enterprise ccjhRepl1:PRIMARY> rs.config()
{
	"_id" : "ccjhRepl1", #副本集名称
	"version" : 1, # 文件的版本（修改次数）
	"protocolVersion" : NumberLong(1),
	"members" : [# 该副本集成员
		{
			"_id" : 0, # 成员编号
			"host" : "192.168.31.91:22101",# 成员地址
			"arbiterOnly" : false,#是否为仲裁节点
			"buildIndexes" : true,#是否可以建立索引
			"hidden" : false,# 是否为隐藏节点
			"priority" : 1,# 成为主节点的优先级
			"tags" : {
				
			},
			"slaveDelay" : NumberLong(0),# 延迟多长时间开始复制最新数据
			"votes" : 1
		},
		{
			"_id" : 1,
			"host" : "192.168.31.91:22202",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 1,
			"tags" : {
				
			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		},
		{
			"_id" : 2,
			"host" : "192.168.31.91:22303",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 1,
			"tags" : {
				
			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		}
	],
	"settings" : {
		"chainingAllowed" : true,
		"heartbeatIntervalMillis" : 2000,
		"heartbeatTimeoutSecs" : 10,
		"electionTimeoutMillis" : 10000,
		"catchUpTimeoutMillis" : -1,
		"catchUpTakeoverDelayMillis" : 30000,
		"getLastErrorModes" : {
			
		},
		"getLastErrorDefaults" : {
			"w" : 1,
			"wtimeout" : 0
		},
		"replicaSetId" : ObjectId("5a9f87171d98ad596bcd6418")
	}
}

```

### rs 命令

- rs.initiate(config); 初始化副本集
- rs.add("host") 添加新成员到副本集中
- rs.remove("host") 删除副本集中的某一个节点
- rs.config() 查看副本集配置
- rs.reConfig(config) 修改副本集配置

### 副本集选举机制

****

- 主节点必须得到大多数的支持才能成为主节点，失去支持就立刻变成普通的备份节点
- 当一个成员失去与主节点的连接的时候，它就会推举自己成为主节点，并且需要接受其它节点的考核，考核内容有，自己是否可以连接主节点，该节点的数据是不是最新可达成员中最新的等，如果复合条件那么该节点就会成为主节点，反之如果大多数中有一个节点因为某种原因反对那么当前节点暂时将不能成为主节点。需要再有新的主节点出现之前再此申请并得到多数的支持才可以成为主节点。
- 每个成员只能推举自己作为主节点，不可以推荐其他节点成为主节点。
- 当每一方都不够大多数的时候那么将没有主节点，也就是说这时服务将处于不可用状态

### 节点说明

**仲裁节点：**

仲裁节点不储存数据，主要用于凑数，假如该副本节点是偶数个，当每一方都一样都凑不够大多数的情况下，仲裁节点有决定性的一票，可以通过addArb()添加总裁节点，需要注意仲裁节点是不可逆的反之亦然。并且如果考虑节点应该作为仲裁节点还是副本节点的时候最好作为副本节点，如果是副本数是偶数的时候才考虑使用仲裁节点，如果副本数是奇数时使用仲裁节点将是一个很坏的打算。

**节点的索引：**

如果觉得某节点可以不用索引，那么可以将buildIndexes:设置为false那么这个节点将不能创建索引。请注意这是不可逆的。该节点也不能成为主节点。

**优先级:**

顾名思义优先级高的成员会优先成为主节点，举个例子，如果much01的优先级是1，much02的优先级是2，much03的优先级是1，当前的主节点是much01的话，如果much02的数据成为最新数据那么much02会立刻成为主节点，反之如果much02的数据一直不是最新的那么它将一致不能成为主节点。优先级为0的成员永远不可能成为主节点。这样的成员被称为被动成员。

**隐藏节点：**

只有优先级为0的节点才能成为隐藏节点客户端不会向隐藏成员发送请求，隐藏成员也不会作为复制源（当其它复制源不可用时，它也会被使用的）。因此，很多人会将不够强大的服务器或者备份服务器隐藏起来，可以通过修改节点的hidden属性来实现。节点隐藏后rs.isMaster()将不能探测到该节点。但是rs.status()和rs.config()可以看到隐藏成员。因为客户是通过isMaster()来查看可用成员的。隐藏成员是可逆的。

**延迟备份节点：**

数据库可能因为认为错误造成毁灭性的破坏如：被不小心删除了，延迟备份节点可以在主节点被删除后还保留之前的数据，可以将数据从先前的备份中恢复过来。通过slaveDelay可以修改成员为延迟备份节点，要求优先级为0作者：



## 副本集添加密码

### 添加管理用户

```shell
# 注意要在 admin 数据库中添加
MongoDB Enterprise ccjhRepl1:PRIMARY> db.createUser({user:"gameMirror",pwd:"ccjhGameMirror",roles:[{role:"userAdminAnyDatabase",db:"admin"},{role:"clusterAdmin",db:"admin"}]});

Successfully added user: {
	"user" : "gameMirror",
	"roles" : [
		{
			"role" : "userAdminAnyDatabase",
			"db" : "admin"
		},
		{
			"role" : "clusterAdmin",
			"db" : "admin"
		}
	]
}

```



### 生成密码文件

```shell
# 生成密钥文件
gamemirror@GameMirror ~/r/ccjhRepl> openssl rand -base64 666 > /home/gamemirror/repl/ccjhRepl/mongodb.key
# 修改权限
gamemirror@GameMirror ~/r/ccjhRepl> chmod 400 mongodb.key 
```

### 修改配置

***注意***

在修改配置文件之前，要停止当前的mongodb 进程

```shell
# 在配置中添加 如下内容
security:
  keyFile: "/home/gamemirror/repl/ccjhRepl/mongodb.key"
  clusterAuthMode: "keyFile"
  authorization: "enabled"
```

##### 重启服务器

```shell
gamemirror@GameMirror ~/r/ccjhRepl> mongod -f ./shard1/mongo.conf
gamemirror@GameMirror ~/r/ccjhRepl> mongod -f ./shard2/mongo.conf
gamemirror@GameMirror ~/r/ccjhRepl> mongod -f ./shard3/mongo.conf
gamemirror@GameMirror ~/r/ccjhRepl> mongo --host 192.168.31.91 --port 22202
MongoDB shell version v3.6.1
connecting to: mongodb://192.168.31.91:22202/
MongoDB server version: 3.6.1
MongoDB Enterprise ccjhRepl1:SECONDARY> use admin
switched to db admin
MongoDB Enterprise ccjhRepl1:SECONDARY> db.auth("gameMirror","ccjhGameMirror")
```

### 给新的数据库，添加用户验证

**说明**

​	非管理数据库，常用的有两种权限：

- read 只读
- readWrite 读写

用户和授权认证是跟随数据库的，在那个库里面创建的用户，就要在那里授权认证。

```shell
gamemirror@GameMirror ~/r/ccjhRepl> mongo --host 192.168.31.91 --port 22101
MongoDB shell version v3.6.1
connecting to: mongodb://192.168.31.91:22101/
MongoDB server version: 3.6.1
# admin 登录认证，不然没有操作权限
MongoDB Enterprise ccjhRepl1:PRIMARY> use admin
switched to db admin
MongoDB Enterprise ccjhRepl1:PRIMARY> db.auth("gameMirror","ccjhGameMirror")
1
# 创建新数据库
MongoDB Enterprise ccjhRepl1:PRIMARY> use ccjh_frank
switched to db ccjh_frank
# 添加 读写权限用户
MongoDB Enterprise ccjhRepl1:PRIMARY> db.createUser({user:"frank",pwd:"ccjhGameMirror",roles:[{role:"readWrite",db:"ccjh_frank"}]})
Successfully added user: {
	"user" : "frank",
	"roles" : [
		{
			"role" : "readWrite",
			"db" : "ccjh_frank"
		}
	]
}
# 创建 只读用户
MongoDB Enterprise ccjhRepl1:PRIMARY> db.createUser({user:"frankR",pwd:"ccjhGameMirror",roles:[{role:"read",db:"ccjh_frank"}]})
Successfully added user: {
	"user" : "frankR",
	"roles" : [
		{
			"role" : "read",
			"db" : "ccjh_frank"
		}
	]
}
```

#### 常用数据库用户操作

+ 添加用户权限：
  + createUser : db.createUser({user:"用户名",pwd:"用户密码",roles:[{role:"权限",db:"数据库"}]})
+ 修改用户权限
  + **grantRolesToUser** 原有基础上追加权限。
    + db.grantRolesToUser("用户名",[{role:"权限",db:"数据库"}])
  + **updateUser** 替换原有的权限
    + db.updateUser("用户名",[{role:"权限",db:"数据库"}])
+ 删除用户权限
  + **revokeRolesFromUser**  db.revokeRolesFromUser("用户名",[{role:"权限",db:"数据库"}])

##### oplog读权限

oplog是一种特殊的Capped collections，特殊之处在于它是系统级Collection，记录了数据库的所有操作，集群之间依靠oplog进行数据同步。oplog的全名是local.oplog.rs，位于local数据下。由于local数据不允许创建用户，如果要访问oplog需要借助其它数据库的用户，并且赋予该用户访问local数据库的权限:

+ 修改现有用户，使其具有oplog的读权限：

  db.grantRolesToUser("用户名",[{role:"read",db:"local"}])

+ 创建新用户：

db.creatUser({user:"用户名",pwd:"密码",roles:[{role:"read",db:"数据库"},{role:"read",db:"local"}]})

+ 查询过程：

  ```shell
  >use  数据库

  >db.auth('用户名','密码')

  >use local

  >db.oplog.rs.find()
  ```

## 压力测试

### 压力测试脚本

```shell
class InsertTest
{
	static async InsertData(data)
	{
		return await mongodb.dbSchema.createNewData(data);
	}

	static CreateData(index)
	{
		const data = {
			gId    : GetIdByTypeName('InsertTest'),
			gName  : `InsertData_${index}`,
			groups : ['news', 'sports'],
			age    : parseInt(Math.random() * 100)
		};
		return data;
	}
	// 每次插入1条数据
	static async Insert100WData()
	{
		const time = process.uptime();
		let i = 0;
		for (i = 0; i < 1000000; i++)
		{
			await InsertTest.InsertData(InsertTest.CreateData(i));
		}
		console.info(`插入 100 万条数据执行的时间 ${process.uptime() - time}`);
	}
	// 每次插入100 条数据
	static async Insert100WData2()
	{
		const time = process.uptime();
		let i = 0;
		let test = [];
		for (i = 0; i < 10000; i++)
		{
			test = [];
			for (let j = 0; j < 100; j++)
			{
				test.push(InsertTest.InsertData(InsertTest.CreateData(j)));
			}
			await Promise.all(test);
		}

		console.info(`插入 100 万条数据执行的时间 ${process.uptime() - time}`);
	}
}

InsertTest.Insert100WData2();
```

### 测试结果

每次插入100 条数据    测试结果

> 插入 100 万条数据执行的时间 535.914 s
>
> 经计算
>
> 平均每秒插入数据 1865 条
>
> cpu 占用： 30%~80%
>
> 内存占用
>
> insert  getmore command dirty  used flushes vsize  res qrw arw net_in net_out conn 
>   1876              8        10|0    2.2% 11.5%       0 2.36G 949M 0|2 1|1   481k   1.07m   12 
>   2022              9        13|0    2.2% 11.5%       0 2.36G 951M 0|0 1|0   518k   1.04m   12 
>   1800              5        10|0    2.2% 11.5%       0 2.36G 953M 0|0 1|0   459k    870k   12 
>   1836              8        11|0    2.2% 11.5%       0 2.36G 954M 0|1 1|0   471k   1.33m   12 
>   1861            14        19|0    2.2% 11.5%       0 2.37G 958M 0|0 1|0   487k   1.15m   12 
>   2102            12        17|0    2.2% 11.5%       0 2.37G 958M 0|0 1|0   543k   1.09m   12 
>   1700           14        20|0    2.3% 11.6%       0 2.37G 960M 0|0 1|0   445k    966k   12 
>   1900           14        19|0    2.3% 11.6%       0 2.37G 962M 0|0 1|0   495k   1.10m   12 
>   1997           17        17|0    2.3% 11.6%       0 2.37G 964M 0|0 1|0   520k   1.10m   12 
>   1801           19        23|0    2.3% 11.6%       0 2.37G 964M 0|0 1|0   475k    937k   12 
> insert  getmore command dirty  used flushes vsize  res qrw arw net_in net_out conn 
>   1843           12        19|0    2.4% 11.7%       0 2.37G 963M 0|0 1|0   478k   1.07m   12 
>   2063           10        14|0    2.4% 11.7%       0 2.38G 967M 0|0 1|0   530k   1.10m   12 
>   1794           10        14|0    2.4% 11.7%       0 2.38G 969M 0|0 1|0   464k   1.04m   12 
>   1944           11        20|0    2.4% 11.7%       0 2.38G 969M 0|0 1|0   503k   1.12m   12 
>   1858           15        17|0    2.5% 11.8%       0 2.38G 971M 0|0 1|0   484k   1.12m   12 
>   1598           21        24|0    2.5% 11.8%       0 2.38G 971M 0|0 1|0   427k    934k   12 
>   1898           17        20|0    2.5% 11.8%       0 2.40G 973M 0|0 1|0   497k   1.07m   12 
>    600                6         9|0    2.5% 11.8%       0 2.40G 975M 0|0 1|0   158k    435k   12 

每次插入1 条数据    测试结果

> 插入 100 万条数据执行的时间 2451.687
>
> 平均每秒插入数据 408 条
>
> cpu 占用： 23%~33%
>
> 内存占用
>
> res 最高 1.11G
>
> vsize 最高 2.57G
>
> insert getmore command dirty  used flushes vsize   res qrw arw net_in net_out conn
>    348   22    24|0  0.8% 14.2%       0 2.55G 1.10G 0|0 2|0   115k    296k   11
>    393   22    26|0  0.9% 14.2%       0 2.55G 1.10G 0|0 1|0   127k    268k   11
>    394   25    27|0  0.9% 14.2%       0 2.55G 1.10G 0|0 1|0   129k    298k   11
>    387   20    23|0  0.9% 14.2%       0 2.57G 1.10G 0|0 1|0   123k    285k   11
>    372   22    24|0  0.9% 14.2%       0 2.57G 1.10G 0|1 1|0   120k    267k   11
>    382   20    23|0  0.9% 14.2%       1 2.57G 1.10G 0|0 1|0   122k    276k   11
>    348    7    10|0  0.2% 14.2%       0 2.57G 1.10G 0|0 1|0  97.2k    174k   11
>    393    4     8|0  0.2% 14.2%       0 2.57G 1.10G 0|0 1|0   107k    307k   11
>    389    6     8|0  0.2% 14.2%       0 2.57G 1.10G 0|0 1|0   106k    296k   11
>    391    8    12|0  0.2% 14.2%       0 2.57G 1.10G 0|0 1|0   111k    269k   11
> insert getmore command dirty  used flushes vsize   res qrw arw net_in net_out conn
>    405   15    22|0  0.3% 14.2%       0 2.57G 1.10G 0|0 1|0   122k    269k   11
>    351   21    25|0  0.3% 14.2%       0 2.57G 1.10G 0|0 1|0   114k    304k   11
>    482   18    20|0  0.3% 14.2%       0 2.57G 1.11G 0|0 1|0   145k    312k   11
>    503   19    22|0  0.3% 14.2%       0 2.57G 1.11G 0|1 1|0   151k    329k   11
>    495   22    24|0  0.3% 14.2%       0 2.57G 1.11G 0|0 1|0   152k    350k   11
>    504   18    21|0  0.3% 14.2%       0 2.57G 1.11G 0|0 1|0   151k    347k   11
>    466    9    12|0  0.3% 14.3%       0 2.57G 1.11G 0|1 1|0   130k    271k   11
>    499    9    17|0  0.3% 14.3%       0 2.57G 1.11G 0|0 1|0   139k    337k   11
>    510    9    13|0  0.4% 14.3%       0 2.57G 1.11G 0|0 1|0   143k    367k   11
>    503   12    16|0  0.4% 14.3%       0 2.57G 1.11G 0|0 1|0   142k    328k   11
> insert getmore command dirty  used flushes vsize   res qrw arw net_in net_out conn
>    505   17    19|0  0.4% 14.3%       0 2.57G 1.11G 0|1 1|0   150k    335k   11
>    401   21    25|0  0.4% 14.3%       0 2.57G 1.11G 0|0 1|0   128k    306k   11
>    430   16    18|0  0.4% 14.3%       0 2.57G 1.11G 0|1 1|0   128k    303k   11
>    379   31    34|0  0.4% 14.3%       0 2.57G 1.11G 0|1 1|0   132k    293k   11
>    384   22    24|0  0.4% 14.3%       0 2.57G 1.11G 0|0 1|0   124k    268k   11
>    390   32    39|0  0.4% 14.3%       0 2.57G 1.11G 0|0 1|0   137k    302k   11
>    339   17    20|0  0.5% 14.3%       0 2.57G 1.11G 0|0 1|0   107k    250k   11
>    381   11    14|0  0.5% 14.3%       0 2.57G 1.11G 0|1 1|0   110k    244k   11
>    388    9    11|0  0.5% 14.3%       0 2.57G 1.11G 0|0 1|0   111k    280k   11
>    388   10    14|0  0.5% 14.3%       0 2.57G 1.11G 0|0 2|0   112k    271k   11

### 结论

- 单个命令最多同时插入50 条数据
- 定时维护数据库，清理数据库所占用的内存
- mongodb 直接用操作系统的内存管理器来管理内存。而操作系统采用的是LRU算法淘汰冷数据。 
- mongodb可以用重启服务、调整内核参数以及mongodb内部的语法去清理mongodb对内存的缓存。可能存在的问题是：这几种清理方式都是全部清理，这样的话mongodb的内存缓存就失效了。 
- mongodb 对内存的使用是可以被监控的，在生产环境中要定时的去监控这些数据。 
- mongodb 对内存这种占用方式使其尽量的和其他占用内存的业务分开部署，例如memcahe，sphinx，mysql等。 
- 操作系统中的交换分区swap 如果操作频繁的话，会严重降低系统效率。要解决可以禁用交换分区，以及增加内存以及做分布式。 
- 生产环境中mongodb所在的主机应该尽量的大内存。 
- 在数据达到一定量时，可以考虑采用分片集群，降低数据对单个复制集的压力