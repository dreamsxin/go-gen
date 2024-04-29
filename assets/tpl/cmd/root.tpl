package cmd

import (
	"fmt"
	"os"

	"{{.PkgName}}/config"
	"{{.PkgName}}/db"
	"{{.PkgName}}/logger"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "{{ .AppName }}",
	Short: "A brief description of your application",
	Long:  "A longer description that spans multiple lines and likely contains examples and usage of using your application.",
	// Uncomment the following line if your bare application
	// has an action associated with it:
	// Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

var isDebug bool

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	//isDebug = *rootCmd.PersistentFlags().BoolP("debug", "d", false, "Enable debug mode")
	rootCmd.PersistentFlags().BoolVarP(&isDebug, "debug", "d", false, "Enable debug mode")
	viper.BindPFlag("debug", rootCmd.PersistentFlags().Lookup("debug"))

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "config.json", "config file (default is $HOME/.config.json)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)

		viper.AddConfigPath(home)
		viper.SetConfigType("json")
		viper.SetConfigName("config")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
	}

	config.InitConfig(viper.GetViper())
	logger.InitLogger(viper.GetViper())
	db.InitDB(viper.GetViper())
}
