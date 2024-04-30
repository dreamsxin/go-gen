package gen

import (
	"errors"
	"fmt"
	"log"
	"path"

	"github.com/dreamsxin/go-gen/config"
	"github.com/dreamsxin/go-gen/consts"

	"github.com/spf13/viper"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gen"
	"gorm.io/gorm"
)

type Model struct {
	ModuleName   string
	AbsolutePath string
	Tables       []string
	DBName       string
}

func (p *Model) Create() error {
	log.Println("create model")
	var cfgs []config.DBConfig
	viper.UnmarshalKey("dbs", &cfgs)
	var cfg config.DBConfig
	for _, v := range cfgs {
		if v.Name == p.DBName {
			cfg = v
			break
		}
	}

	if cfg.Name == "" {
		return fmt.Errorf("db %q not found", p.DBName)
	}

	if len(p.Tables) == 0 {
		return errors.New("tables must required")
	}
	db, err := p.connectDB(cfg.Driver, cfg.DSN)
	if err != nil {
		log.Fatalln("connect db server fail:", err)
	}

	if p.ModuleName == "" {
		p.ModuleName = cfg.Name
	}

	log.Println("p.AbsolutePath", p.AbsolutePath, "module name:", p.ModuleName)
	g := gen.NewGenerator(gen.Config{
		OutPath:      path.Join(p.AbsolutePath, "modules", p.ModuleName, "models"),
		ModelPkgPath: "models",
	})

	g.UseDB(db)

	_, err = p.genModels(g, db, p.Tables)
	if err != nil {
		log.Fatalln("get tables info fail:", err)
	}

	g.Execute()
	return nil
}

// genModels is gorm/gen generated models
func (p *Model) genModels(g *gen.Generator, db *gorm.DB, tables []string) (models []interface{}, err error) {
	if len(tables) == 0 {
		// Execute tasks for all tables in the database
		tables, err = db.Migrator().GetTables()
		if err != nil {
			return nil, fmt.Errorf("GORM migrator get all tables fail: %w", err)
		}
	}

	// Execute some data table tasks
	models = make([]interface{}, len(tables))
	for i, tableName := range tables {
		models[i] = g.GenerateModel(tableName)
	}
	return models, nil
}

func (p *Model) connectDB(t string, dsn string) (*gorm.DB, error) {
	if dsn == "" {
		return nil, fmt.Errorf("dsn cannot be empty")
	}

	switch t {
	case consts.DB_MySQL:
		return gorm.Open(mysql.Open(dsn))
	case consts.DB_Postgres:
		return gorm.Open(postgres.Open(dsn))
	case consts.DB_SQLite:
		return gorm.Open(sqlite.Open(dsn))
	// case consts.DB_SQLServer:
	// 	return gorm.Open(sqlserver.Open(dsn))
	// case consts.DB_ClickHouse:
	// 	return gorm.Open(clickhouse.Open(dsn))
	default:
		return nil, fmt.Errorf("unknow db %q (support mysql || postgres || sqlite || sqlserver for now)", t)
	}
}
