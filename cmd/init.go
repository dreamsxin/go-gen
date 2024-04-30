package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"github.com/dreamsxin/go-gen/gen"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	initCmd = &cobra.Command{
		Use:     "init [path]",
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
			projectPath, err := initializeProject(path)
			cobra.CheckErr(err)
			fmt.Printf("Your application is ready at: %s\n", projectPath)
		},
	}
)

func init() {
	rootCmd.AddCommand(initCmd)

	initCmd.PersistentFlags().BoolP("force", "f", false, "Force overwrite of existing files")
	viper.BindPFlag("force", rootCmd.PersistentFlags().Lookup("force"))
}

func GetPath(args []string) (string, error) {

	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	if len(args) > 0 {
		if args[0] != "." {
			wd = fmt.Sprintf("%s/%s", wd, args[0])
		}
	}
	return wd, err
}

func initializeProject(dir string) (string, error) {

	pkgName := getModImportPath()

	project := &gen.Project{
		AbsolutePath: dir,
		PkgName:      pkgName,
		AppName:      path.Base(pkgName),
	}

	if err := project.Create(); err != nil {
		return "", err
	}

	return project.AbsolutePath, nil
}

func getModImportPath() string {
	mod, cd := parseModInfo()
	return path.Join(mod.Path, fileToURL(strings.TrimPrefix(cd.Dir, mod.Dir)))
}

func fileToURL(in string) string {
	i := strings.Split(in, string(filepath.Separator))
	return path.Join(i...)
}

func parseModInfo() (Mod, CurDir) {
	var mod Mod
	var dir CurDir

	m := modInfoJSON("-m")
	cobra.CheckErr(json.Unmarshal(m, &mod))

	// Unsure why, but if no module is present Path is set to this string.
	if mod.Path == "command-line-arguments" {
		cobra.CheckErr("Please run `go mod init <MODNAME>` before `go-gen init`")
	}

	e := modInfoJSON("-e")
	cobra.CheckErr(json.Unmarshal(e, &dir))

	return mod, dir
}

type Mod struct {
	Path, Dir, GoMod string
}

type CurDir struct {
	Dir string
}

func modInfoJSON(args ...string) []byte {
	cmdArgs := append([]string{"list", "-json"}, args...)
	out, err := exec.Command("go", cmdArgs...).Output()
	cobra.CheckErr(err)

	return out
}
