package router

import (
	"log"

	"{{.PkgName}}/modules/hello"

	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

var AppRouters = make([]func(r *gin.Engine), 0)

func init() {
	AppRouters = append(AppRouters, hello.InitRouter)
}

func InitRouter(r *gin.Engine, v *viper.Viper) {
	//初始化路由
	for _, f := range AppRouters {
		f(r)
	}
	log.Println("router init success")
}
