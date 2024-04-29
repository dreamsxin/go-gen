package config

type DBConfig struct {
	Name          string `mapstructure:"name" json:"name" yaml:"name"`
	Driver        string `mapstructure:"driver" json:"driver" yaml:"driver"`
	DSN           string `mapstructure:"dsn" json:"dsn" yaml:"dsn"`
	Disable       bool   `mapstructure:"disable" json:"disable" yaml:"disable"`
	Prefix        string `mapstructure:"prefix" json:"prefix" yaml:"prefix"`
	Singular      bool   `mapstructure:"singular" json:"singular" yaml:"singular"`
	MaxIdle       int    `mapstructure:"maxIdle" json:"maxIdle" yaml:"maxIdle"`
	MaxOpen       int    `mapstructure:"maxOpen" json:"maxOpen" yaml:"maxOpen"`
	MaxLifetime   int    `mapstructure:"maxLifetime" json:"maxLifetime" yaml:"maxLifetime"`
	LogMode       string `mapstructure:"logMode" json:"logMode" yaml:"logMode"`
	SlowThreshold int    `mapstructure:"slow-threshold" json:"slow-threshold" yaml:"slow-threshold"`
}

func (c DBConfig) GetDSN() string {
	return c.DSN
}

func (c DBConfig) GetDriver() string {
	return c.Driver
}
