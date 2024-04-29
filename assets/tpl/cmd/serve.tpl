package cmd

import (
	"{{.PkgName}}/debug"
	"{{.PkgName}}/middleware"
	"{{.PkgName}}/router"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// serveCmd represents the serve command
var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "Start Application",
	Long:  "Starts the application and listens for incoming requests",
	Run: func(cmd *cobra.Command, args []string) {
		run()
	},
}

func init() {
	rootCmd.AddCommand(serveCmd)
	viper.SetDefault("addr", ":8080")
}

func run() {
	r := gin.Default()
	middleware.InitMiddleware(r, viper.GetViper())
	router.InitRouter(r, viper.GetViper())
	log.Println("debug", isDebug, viper.GetBool("debug"))
	if isDebug {
		debug.InitDebug()
	}
	r.Run(viper.GetString("addr")) // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}
