

## 安装使用

```shell
go install github.com/dreamsxin/go-gen@latest
mkdir test && cd test
go mod init hello
go-gen init
```

### 生成 model

```shell
# 配置数据库 config.json
vi config.json
# 生成 user model
go-gen model -d hello -t user
```

