package config

type LogConfig struct {
	Level       string `mapstructure:"level" json:"level" yaml:"level"`                      // 级别
	Prefix      string `mapstructure:"prefix" json:"prefix" yaml:"prefix"`                   // 日志前缀
	Format      string `mapstructure:"format" json:"format" yaml:"format"`                   // 输出
	Dir         string `mapstructure:"dir" json:"dir"  yaml:"dir"`                           // 日志文件夹
	MaxAge      int    `mapstructure:"maxAge" json:"maxAge" yaml:"maxAge"`                   // 日志留存时间 天
	EncodeLevel string `mapstructure:"encode-level" json:"encode-level" yaml:"encode-level"` // 编码级
	Console     bool   `mapstructure:"console" json:"console" yaml:"console"`                // 输出控制台
}
