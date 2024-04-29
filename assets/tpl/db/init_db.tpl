package db

import (
	"database/sql"
	"log"
	"path"
	"sync"
	"time"

	"{{.PkgName}}/config"
	"{{.PkgName}}/logger"

	"github.com/spf13/viper"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

var (
	lock sync.RWMutex
	dbs  = make(map[string]*gorm.DB, 0)
)

func InitDB(v *viper.Viper) {
	if len(config.DBS()) <= 0 {
		logger.Sugar().DPanic("db config empty")
	}
	logger.Sugar().Infof("init db %#v", config.DBS())
	for _, cfg := range config.DBS() {
		initDb(cfg)
	}
}

func initDb(cfg config.DBConfig) {
	var db *gorm.DB
	var err error
	var dialector gorm.Dialector
	switch cfg.Driver {
	case "mysql":
		dialector = mysql.Open(cfg.DSN)
	case "postgres":
		dialector = postgres.Open(cfg.DSN)
	case "sqlite":
		dialector = sqlite.Open(cfg.DSN)
	default:
		logger.Sugar().DPanic("db err: driver not found")
	}

	gormcfg := &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			TablePrefix:   cfg.Prefix,
			SingularTable: cfg.Singular,
		},
	}

	filePath := path.Join(config.Log().Dir, "%Y-%m-%d", "sql.log")
	w, err := logger.Rotatelog(filePath)
	if err != nil {
		logger.Sugar().DPanicf("db err: %s", err.Error())
	}
	slow := time.Duration(cfg.SlowThreshold) * time.Millisecond

	gormcfg.Logger = gormlogger.New(log.New(w, "", log.LstdFlags), gormlogger.Config{
		SlowThreshold: slow,
		Colorful:      false,
		LogLevel:      gormlogger.Info,
	})

	db, err = gorm.Open(dialector, gormcfg)
	if err != nil {
		logger.Sugar().DPanicf("db: %s dns: %s err: %s", cfg.Name, cfg.DSN, err.Error())
	}

	var sqlDB *sql.DB
	sqlDB, err = db.DB()
	if err != nil {
		logger.Sugar().DPanicf("db: %s dns: %s err: %s", cfg.Name, cfg.DSN, err.Error())
	}
	sqlDB.SetMaxIdleConns(cfg.MaxIdle)
	sqlDB.SetMaxOpenConns(cfg.MaxOpen)
	sqlDB.SetConnMaxLifetime(time.Minute * time.Duration(cfg.MaxLifetime))

	lock.Lock()
	defer lock.Unlock()
	dbs[cfg.Name] = db
}

func DBS() map[string]*gorm.DB {
	return dbs
}

func DB(name string) *gorm.DB {
	lock.RLock()
	defer lock.RUnlock()
	db, ok := dbs[name]
	if !ok || db == nil {
		logger.Sugar().DPanicf("db: %s not init", name)
	}
	return db
}
