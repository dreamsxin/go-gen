package logger

import (
	"log"
	"os"
	"path"
	"strings"
	"time"

	"{{.PkgName}}/config"

	rotatelogs "github.com/lestrrat-go/file-rotatelogs"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var logger *zap.Logger

func init() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

func InitLogger(v *viper.Viper) *zap.Logger {
	var err error
	debug := v.GetBool("debug")
	// if debug {
	// 	logger, err = zap.NewDevelopment()
	// } else {
	// 	logger, err = zap.NewProduction()
	// }
	// if err != nil {
	// 	log.Fatalf("logger init failed, err: %v", err)
	// }
	log.Println("logger init success", debug)

	_, err = os.Stat(config.Log().Dir)
	if !os.IsExist(err) {
		err = os.MkdirAll(config.Log().Dir, os.ModePerm)
		if err != nil {
			log.Fatalf("logger init failed, err: %v", err)
		}
	}

	cores := make([]zapcore.Core, 0, 7)
	for level := GetZapLevel(); level <= zapcore.FatalLevel; level++ {
		cores = append(cores, GetEncoderCore(level, GetLevelEnabler(level)))
	}
	logger = zap.New(zapcore.NewTee(cores...)).WithOptions(zap.AddCaller())
	return logger
}

func GetEncoderCore(l zapcore.Level, level zap.LevelEnablerFunc) zapcore.Core {
	filePath := path.Join(config.Log().Dir, "%Y-%m-%d", l.String()+".log")

	w, err := Rotatelog(filePath)
	if err != nil {
		log.Fatalf("logger init failed, err: %v", err)
		return nil
	}
	return zapcore.NewCore(GetEncoder(), w, level)
}

func GetEncoder() zapcore.Encoder {
	encoderConfig := zapcore.EncoderConfig{
		MessageKey:     "message",
		LevelKey:       "level",
		TimeKey:        "time",
		NameKey:        "logger",
		CallerKey:      "caller",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    ZapEncodeLevel(),
		EncodeTime:     zapcore.RFC3339TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.FullCallerEncoder,
	}

	if config.Log().Format == "json" {
		return zapcore.NewJSONEncoder(encoderConfig)
	}
	return zapcore.NewConsoleEncoder(encoderConfig)
}

func ZapEncodeLevel() zapcore.LevelEncoder {
	switch config.Log().EncodeLevel {
	case "LowercaseLevelEncoder": // 小写编码器(默认)
		return zapcore.LowercaseLevelEncoder
	case "LowercaseColorLevelEncoder": // 小写编码器带颜色
		return zapcore.LowercaseColorLevelEncoder
	case "CapitalLevelEncoder": // 大写编码器
		return zapcore.CapitalLevelEncoder
	case "CapitalColorLevelEncoder": // 大写编码器带颜色
		return zapcore.CapitalColorLevelEncoder
	default:
		return zapcore.LowercaseLevelEncoder
	}
}

func GetZapLevel() zapcore.Level {
	switch strings.ToLower(config.Log().Level) {
	case "debug":
		return zapcore.DebugLevel
	case "info":
		return zapcore.InfoLevel
	case "warn":
		return zapcore.WarnLevel
	case "error":
		return zapcore.WarnLevel
	case "dpanic":
		return zapcore.DPanicLevel
	case "panic":
		return zapcore.PanicLevel
	case "fatal":
		return zapcore.FatalLevel
	default:
		return zapcore.DebugLevel
	}
}

func GetLevelEnabler(level zapcore.Level) zap.LevelEnablerFunc {
	switch level {
	case zapcore.DebugLevel:
		return func(level zapcore.Level) bool { // 调试级别
			return level == zap.DebugLevel
		}
	case zapcore.InfoLevel:
		return func(level zapcore.Level) bool { // 日志级别
			return level == zap.InfoLevel
		}
	case zapcore.WarnLevel:
		return func(level zapcore.Level) bool { // 警告级别
			return level == zap.WarnLevel
		}
	case zapcore.ErrorLevel:
		return func(level zapcore.Level) bool { // 错误级别
			return level == zap.ErrorLevel
		}
	case zapcore.DPanicLevel:
		return func(level zapcore.Level) bool { // dpanic级别
			return level == zap.DPanicLevel
		}
	case zapcore.PanicLevel:
		return func(level zapcore.Level) bool { // panic级别
			return level == zap.PanicLevel
		}
	case zapcore.FatalLevel:
		return func(level zapcore.Level) bool { // 终止级别
			return level == zap.FatalLevel
		}
	default:
		return func(level zapcore.Level) bool { // 调试级别
			return level == zap.DebugLevel
		}
	}
}

func Sugar() *zap.SugaredLogger {
	return logger.Sugar()
}

func Debug(v ...any) {
	logger.Sugar().Debug(v...)
}

func Debugln(v ...any) {
	logger.Sugar().Debugln(v...)
}

func Error(v ...any) {
	logger.Sugar().Error(v...)
}

func Errorln(v ...any) {
	logger.Sugar().Errorln(v...)
}

// 日志文件切割
func Rotatelog(filename string) (zapcore.WriteSyncer, error) {
	//保存日志30天，每1分钟分割一次日志
	hook, err := rotatelogs.New(
		filename,
		rotatelogs.WithClock(rotatelogs.Local),
		rotatelogs.WithMaxAge(24*time.Hour*time.Duration(config.Log().MaxAge)),
		rotatelogs.WithRotationTime(time.Hour*24),
	)
	if config.Log().Console {
		return zapcore.NewMultiWriteSyncer(zapcore.AddSync(os.Stdout), zapcore.AddSync(hook)), err
	}
	return zapcore.AddSync(hook), err
}
