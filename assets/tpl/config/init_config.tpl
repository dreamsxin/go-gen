package config

import (
	"log"

	"github.com/spf13/viper"
)

var (
	config *Config

	dbs = make(map[string]*DBConfig, 0)
)

type Config struct {
	Server ServerConfig `mapstructure:"server" json:"server" yaml:"server"`
	DBS    []DBConfig   `mapstructure:"dbs" json:"dbs" yaml:"dbs"`
	Log    LogConfig    `mapstructure:"log" json:"log" yaml:"log"`
}

func InitConfig(v *viper.Viper) *Config {
	err := v.Unmarshal(&config)
	if err != nil {
		log.Panicf("config init failed, err:%v", err)
	}
	for _, cfg := range config.DBS {
		dbs[cfg.Name] = &cfg
	}
	return config
}

func Server() ServerConfig {
	return config.Server
}

func DBS() []DBConfig {
	return config.DBS
}

func DB(name string) *DBConfig {
	cfg, ok := dbs[name]
	if ok {
		return cfg
	}
	log.Panicf("db config not found: %s", name)
	return nil
}

func Log() LogConfig {
	return config.Log
}
