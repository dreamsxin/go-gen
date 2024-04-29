package config

type ServerConfig struct {
	Name string `mapstructure:"name" json:"name" yaml:"name"` //appname
	Mode string `mapstructure:"mode" json:"mode" yaml:"mode"` //模式
	Host string `mapstructure:"host" json:"host" yaml:"host"` //host
	Port int    `mapstructure:"port" json:"port" yaml:"port"` //port
}
