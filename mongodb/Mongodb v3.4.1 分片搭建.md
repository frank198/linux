# Mongodb v3.4.1 分片搭建

## 搭建环境

系统：ubuntu

```shell
root@ubuntu ~# lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 16.04.1 LTS
Release:	16.04
Codename:	xenial
root@ubuntu ~# mongod --version
db version v3.4.1
git version: 5e103c4f5583e2566a45d740225dc250baacfbd7
OpenSSL version: OpenSSL 1.0.2g  1 Mar 2016
allocator: tcmalloc
modules: enterprise 
build environment:
    distmod: ubuntu1604
    distarch: x86_64
    target_arch: x86_64
```

## 使用分片的条件

- 硬盘容量不足
- 单个mongod满足不了写数据的性能需求
- 需要将大量数据存储在内存中，提高性能

## 分片构成

### 片（单个 mongod 或 副本集）

保存子集合数据的容器，可以是 单个服务器，也可以是副本集。在生产环境中，为了数据的安全性，最好是一个副本集

### mongos (路由器进程)

接收以及处理所有连接的请求，然后将结果聚合返回，其本身并不存储数据或配置信息，但是会缓存配置服务器的信息

### 配置服务器（config server）

存储集群的配置信息：数据和片的对应关系。配置服务器不需要很多空间和资源，因为其本身只是保留一个关系链.配置服务器的副本集满足以下条件：

1. 没有仲裁节点
2. 没有延迟
3. 必须建立索引（buildIndexes:true）
4. 存在 admin 数据库 和 配置数据库， 且admin 数据库包含身份验证和授权
5. 应避免在正常操作或维护过程中直接写入数据到配置服务器
6. 当写入数据到配置服务器时，应该设置 write conncern 为 majority　状态
7. `config`在配置服务器上进行任何维护之前，请始终备份数据库。
8. 访问配置服务器，使用　use config



### 分片的启动过程

1. 配置服务器
2. mongos
3. 片



## 分片搭建

### 副本集分片构成
3个mongos, 1个配置服务器(副本集)，3个分片副本集（1主1从1仲裁）

mongos端口分配:

- 50000
- 60000
- 50888

配置服务器（config server）端口分配:

- 50001
- 60101
- 50101

分片副本集（1主1从1仲裁）端口分配：

- 分片1
  - 50201
  - 60201
  - 50002
- 分片2
  - 50301
  - 60301
  - 50003
- 分片3
  - 50401
  - 60401
  - 50004


### 创建分片文件目录





创建3个副本集，用于做分片集群

```she
gamemirror@GameMirror ~/repl> mkdir -p ./ccjhShard/{mongosRepl,configRepl,dataRepl1,dataRepl2,dataRepl3}/{shard1,shard2,shard3}/{data,log}/
gamemirror@GameMirror ~/repl> tree ccjhShard/
ccjhShard/
├── configRepl
│   ├── shard1
│   │   ├── data
│   │   └── log
│   ├── shard2
│   │   ├── data
│   │   └── log
│   └── shard3
│       ├── data
│       └── log
├── dataRepl1
│   ├── shard1
│   │   ├── data
│   │   └── log
│   ├── shard2
│   │   ├── data
│   │   └── log
│   └── shard3
│       ├── data
│       └── log
├── dataRepl2
│   ├── shard1
│   │   ├── data
│   │   └── log
│   ├── shard2
│   │   ├── data
│   │   └── log
│   └── shard3
│       ├── data
│       └── log
├── dataRepl3
│   ├── shard1
│   │   ├── data
│   │   └── log
│   ├── shard2
│   │   ├── data
│   │   └── log
│   └── shard3
│       ├── data
│       └── log
└── mongosRepl
    ├── shard1
    │   └── log
    ├── shard2
    │   └── log
    └── shard3
        └── log
45 directories, 0 files
```

### 分配端口，写配置文件

#### 配置文件参数说明

#### 共用配置文件 baseMongo.conf

```shell
root@ubuntu /h/f/c/m/cluster# vim baseMongo.conf
# ##########################################################################
net:
  bindIp: 192.168.31.150

processManagement:
  fork: true

systemLog:
  destination: file
  logAppend: true
```

#### mongos 的配置文件 mongo.conf

```shell
root@ubuntu /h/f/c/m/cluster# vim ./repl1/mongos/mongo.conf
include /home/frank/cluster/mongodb/cluster/baseMongo.conf
# ##########################################################################
net:
  port: 22000

sharding:
  configDB: ccjh/192.168.31.150:20001,192.168.31.150:30001,192.168.31.150:40001

systemLog:
  path: /home/frank/cluster/mongodb/cluster/repl1/mongos/log/mongos.log
```

#### config 的配置文件 mongo.conf

```shell
root@ubuntu /h/f/c/m/cluster# vim ./repl1/config/mongo.conf
include /home/frank/cluster/mongodb/cluster/baseMongo.conf
# ##########################################################################
net:
  port: 20001

replication:
  replSetName: ccjh

sharding:
  clusterRole: configsvr

storage:
  dbPath: /home/frank/cluster/mongodb/cluster/repl1/config/data

systemLog:
  path: /home/frank/cluster/mongodb/cluster/repl1/config/log/config.log
```

#### shard 的配置文件 mongo.conf

```shell
root@ubuntu /h/f/c/m/cluster# vim ./repl1/shard1/mongo.conf
include /home/frank/cluster/mongodb/cluster/baseMongo.conf
# ##########################################################################
net:
  port: 22001

replication:
  replSetName: ccjhRepl1

sharding:
  clusterRole: ccjhShard

storage:
  dbPath: /home/frank/cluster/mongodb/cluster/repl1/shard1/data

systemLog:
  path: /home/frank/cluster/mongodb/cluster/repl1/shard1/log/config.log
```

### 启动服务，副本集设置

### config server 副本集启动

```shell
gamemirror@GameMirror ~/r/c/configRepl> mongo --host 192.168.31.91 --port 50001
MongoDB shell version v3.6.1
connecting to: mongodb://192.168.31.91:50001/
MongoDB Enterprise > use admin
switched to db admin
MongoDB Enterprise > config={"_id":"ccjhReplConfig","members":[{"_id":0,"host":"192.168.31.91:50001",priority:5},{"_id":1,"host":"192.168.31.91:50101",priority:3},{"_id":2,"host":"192.168.31.91:60101",priority:1}]}
{
	"_id" : "ccjhReplConfig",
	"members" : [
		{
			"_id" : 0,
			"host" : "192.168.31.91:50001",
			"priority" : 5
		},
		{
			"_id" : 1,
			"host" : "192.168.31.91:50101",
			"priority" : 3
		},
		{
			"_id" : 2,
			"host" : "192.168.31.91:60101",
			"priority" : 1
		}
	]
}
MongoDB Enterprise > rs.initiate(config)
{
	"ok" : 1,
	"operationTime" : Timestamp(1520575937, 1),
	"$gleStats" : {
		"lastOpTime" : Timestamp(1520575937, 1),
		"electionId" : ObjectId("000000000000000000000000")
	},
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520575937, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	}
}
MongoDB Enterprise ccjhReplConfig:SECONDARY> quit()

```

### shard 数据分片启动

```shell
gamemirror@GameMirror ~/r/ccjhShard> mongod -f ./dataRepl1/shard3/mongo.conf 
about to fork child process, waiting until server is ready for connections.
forked process: 433
child process started successfully, parent exiting
gamemirror@GameMirror ~/r/ccjhShard> mongod -f ./dataRepl1/shard2/mongo.conf 
about to fork child process, waiting until server is ready for connections.
forked process: 485
child process started successfully, parent exiting
gamemirror@GameMirror ~/r/ccjhShard> mongod -f ./dataRepl1/shard1/mongo.conf 
about to fork child process, waiting until server is ready for connections.
forked process: 522
child process started successfully, parent exiting
gamemirror@GameMirror ~/r/ccjhShard> mongo --host 192.168.31.91 --port 50002
MongoDB shell version v3.6.1
connecting to: mongodb://192.168.31.91:50002/
MongoDB Enterprise > use admin
switched to db admin
MongoDB Enterprise > config={"_id":"ccjhReplConfig","members":[{"_id":0,"host":"192.168.31.91:50002",priority:5},{"_id":1,"host":"192.168.31.91:50201",priority:3},{"_id":2,"host":"192.168.31.91:60201",arbiterOnly:true}]}
{
	"_id" : "ccjhReplConfig",
	"members" : [
		{
			"_id" : 0,
			"host" : "192.168.31.91:50002",
			"priority" : 5
		},
		{
			"_id" : 1,
			"host" : "192.168.31.91:50201",
			"priority" : 3
		},
		{
			"_id" : 2,
			"host" : "192.168.31.91:60201",
			"arbiterOnly" : true
		}
	]
}
MongoDB Enterprise > rs.initiate(config)
{
	"ok" : 0,
	"errmsg" : "Attempting to initiate a replica set with name ccjhReplConfig, but command line reports ccjhReplShard1; rejecting",
	"code" : 93,
	"codeName" : "InvalidReplicaSetConfig"
}
MongoDB Enterprise > config={"_id":"ccjhReplShard1","members":[{"_id":0,"host":"192.168.31.91:50002",priority:5},{"_id":1,"host":"192.168.31.91:50201",priority:3},{"_id":2,"host":"192.168.31.91:60201",arbiterOnly:true}]}
{
	"_id" : "ccjhReplShard1",
	"members" : [
		{
			"_id" : 0,
			"host" : "192.168.31.91:50002",
			"priority" : 5
		},
		{
			"_id" : 1,
			"host" : "192.168.31.91:50201",
			"priority" : 3
		},
		{
			"_id" : 2,
			"host" : "192.168.31.91:60201",
			"arbiterOnly" : true
		}
	]
}
MongoDB Enterprise > rs.initiate(config)
{ "ok" : 1 }
MongoDB Enterprise ccjhReplShard1:SECONDARY> quit()
// 分别启动另外两个 分片服务器
```

### mongos 路由服务启动与设置

```shell
gamemirror@GameMirror ~/r/ccjhShard> mongos -f ./mongosRepl/shard2/mongo.conf 
about to fork child process, waiting until server is ready for connections.
forked process: 3274
child process started successfully, parent exiting
gamemirror@GameMirror ~/r/ccjhShard> mongo --host 192.168.31.91 --port 50888
MongoDB shell version v3.6.1
connecting to: mongodb://192.168.31.91:50888/
MongoDB Enterprise mongos> use admin
switched to db admin
MongoDB Enterprise mongos> sh.addShard("ccjhReplShard1/192.168.31.91:50002,192.168.31.91:50201,192.168.31.91:60201")
{
	"shardAdded" : "ccjhReplShard1",
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520579654, 3),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	},
	"operationTime" : Timestamp(1520579654, 3)
}
MongoDB Enterprise mongos> sh.addShard("ccjhReplShard2/192.168.31.91:50003,192.168.31.91:50301,192.168.31.91:60301")
{
	"shardAdded" : "ccjhReplShard2",
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520579679, 2),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	},
	"operationTime" : Timestamp(1520579679, 2)
}
MongoDB Enterprise mongos> sh.addShard("ccjhReplShard2/192.168.31.91:50004,192.168.31.91:50401,192.168.31.91:60401")
{
	"shardAdded" : "ccjhReplShard2",
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520579689, 2),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	},
	"operationTime" : Timestamp(1520579689, 2)
}
MongoDB Enterprise mongos> sh.status()
--- Sharding Status --- 
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("5aa225d2fd8ac5fbad4a9c8f")
  }
  shards:
        {  "_id" : "ccjhReplShard1",  "host" : "ccjhReplShard1/192.168.31.91:50002,192.168.31.91:50201",  "state" : 1 }
        {  "_id" : "ccjhReplShard2",  "host" : "ccjhReplShard2/192.168.31.91:50003,192.168.31.91:50301",  "state" : 1 }
  active mongoses:
        "3.6.1" : 3
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours: 
                No recent migrations
  databases:
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }

MongoDB Enterprise mongos> sh.addShard("ccjhReplShard3/192.168.31.91:50004,192.168.31.91:50401,192.168.31.91:60401")
{
	"shardAdded" : "ccjhReplShard3",
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520579761, 2),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	},
	"operationTime" : Timestamp(1520579761, 2)
}
MongoDB Enterprise mongos> sh.status()
--- Sharding Status --- 
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("5aa225d2fd8ac5fbad4a9c8f")
  }
  shards:
        {  "_id" : "ccjhReplShard1",  "host" : "ccjhReplShard1/192.168.31.91:50002,192.168.31.91:50201",  "state" : 1 }
        {  "_id" : "ccjhReplShard2",  "host" : "ccjhReplShard2/192.168.31.91:50003,192.168.31.91:50301",  "state" : 1 }
        {  "_id" : "ccjhReplShard3",  "host" : "ccjhReplShard3/192.168.31.91:50004,192.168.31.91:50401",  "state" : 1 }
  active mongoses:
        "3.6.1" : 3
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours: 
                No recent migrations
  databases:
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }

MongoDB Enterprise mongos> sh.enableSharding("ccjh_frank")
{
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1520579829, 5),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	},
	"operationTime" : Timestamp(1520579829, 5)
}
MongoDB Enterprise mongos> sh.status()
--- Sharding Status --- 
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("5aa225d2fd8ac5fbad4a9c8f")
  }
  shards:
        {  "_id" : "ccjhReplShard1",  "host" : "ccjhReplShard1/192.168.31.91:50002,192.168.31.91:50201",  "state" : 1 }
        {  "_id" : "ccjhReplShard2",  "host" : "ccjhReplShard2/192.168.31.91:50003,192.168.31.91:50301",  "state" : 1 }
        {  "_id" : "ccjhReplShard3",  "host" : "ccjhReplShard3/192.168.31.91:50004,192.168.31.91:50401",  "state" : 1 }
  active mongoses:
        "3.6.1" : 3
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours: 
                No recent migrations
  databases:
        {  "_id" : "ccjh_frank",  "primary" : "ccjhReplShard1",  "partitioned" : true }
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }
                config.system.sessions
                        shard key: { "_id" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                ccjhReplShard1	1
                        { "_id" : { "$minKey" : 1 } } -->> { "_id" : { "$maxKey" : 1 } } on : ccjhReplShard1 Timestamp(1, 0) 
# 设置片键，需要分片的集合设置
MongoDB Enterprise mongos>sh.shardCollection("ccjh_frank.shardTest",{"gId":1})

```

## 分片加上登录验证

