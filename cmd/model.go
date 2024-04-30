package cmd

import (
	"fmt"

	"github.com/dreamsxin/go-gen/gen"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	modelCmd = &cobra.Command{
		Use:     "model [path]",
		Aliases: []string{"initialize", "initialise", "create"},
		Short:   "Initialize a Application",
		Long:    `Initialize will create a new application.`,
		ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
			var comps []string
			var directive cobra.ShellCompDirective
			if len(args) == 0 {
				comps = cobra.AppendActiveHelp(comps, "Optionally specify the path of the go module to initialize")
				directive = cobra.ShellCompDirectiveDefault
			} else if len(args) == 1 {
				comps = cobra.AppendActiveHelp(comps, "This command does not take any more arguments (but may accept flags)")
				directive = cobra.ShellCompDirectiveNoFileComp
			} else {
				comps = cobra.AppendActiveHelp(comps, "ERROR: Too many arguments specified")
				directive = cobra.ShellCompDirectiveNoFileComp
			}
			return comps, directive
		},
		Run: func(_ *cobra.Command, args []string) {
			path, err := GetPath(args)
			cobra.CheckErr(err)
			projectPath, err := initializeModel(path)
			cobra.CheckErr(err)
			fmt.Printf("Your application is ready at: %s\n", projectPath)
		},
	}
)

var (
	tableName  string
	dbName     string
	moduleName string
)

func init() {
	rootCmd.AddCommand(modelCmd)

	modelCmd.PersistentFlags().StringVarP(&tableName, "table", "t", "", "enter the required data table")
	modelCmd.MarkFlagRequired("table")
	viper.BindPFlag("table", rootCmd.PersistentFlags().Lookup("table"))

	modelCmd.PersistentFlags().StringVarP(&dbName, "db", "d", "", "enter the required database name")
	modelCmd.MarkFlagRequired("db")
	viper.BindPFlag("dbname", rootCmd.PersistentFlags().Lookup("dbname"))

	modelCmd.PersistentFlags().StringVarP(&dbName, "module", "m", "", "enter the module name")
	viper.BindPFlag("module", rootCmd.PersistentFlags().Lookup("module"))
}
func initializeModel(dir string) (string, error) {

	model := &gen.Model{
		AbsolutePath: dir,
		ModuleName:   moduleName,
		Tables:       []string{tableName},
		DBName:       dbName,
	}

	if err := model.Create(); err != nil {
		return "", err
	}

	return model.AbsolutePath, nil
}
