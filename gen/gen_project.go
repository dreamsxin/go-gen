package gen

import (
	"encoding/json"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/dreamsxin/go-gen/assets"

	"github.com/spf13/viper"
)

type Project struct {
	PkgName      string
	AbsolutePath string
	AppName      string
}

func (p *Project) Create() error {
	log.Println("create project")
	str, err := json.MarshalIndent(p, "", "\t")
	if err != nil {
		log.Println("err", err)
		return err
	}
	log.Println(string(str))

	// check if AbsolutePath exists
	if _, err := os.Stat(p.AbsolutePath); os.IsNotExist(err) {
		// create directory
		if err := os.Mkdir(p.AbsolutePath, 0754); err != nil {
			return err
		}
	}

	force := viper.GetBool("force")
	err = fs.WalkDir(assets.TplFs, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			log.Println("fs.WalkDir", err)
			return err
		}
		if d.IsDir() {
			return nil
		}
		fileinfo, err := d.Info()
		if err != nil {
			log.Println("fs.DirEntry.Info", err)
			return err
		}
		filename := fileinfo.Name()
		dirpath := filepath.Dir(path)
		ext := filepath.Ext(filename)
		if ext == ".tpl" {
			filename = strings.TrimSuffix(filename, ext) + ".go"
		}

		dstpath := filepath.Join(p.AbsolutePath, strings.TrimPrefix(dirpath, "tpl"), filename)

		if !force {
			_, err := os.Stat(dstpath)
			if err == nil {
				log.Println("file already exists", dstpath)
				return nil
			}
		}
		log.Println("create file", dstpath)

		// create go file
		err = os.MkdirAll(filepath.Dir(dstpath), 0754)
		if err != nil {
			log.Println("os.Create", err)
			return err
		}

		goFile, err := os.Create(dstpath)
		if err != nil {
			log.Println("os.Create", err)
			return err
		}
		defer goFile.Close()

		content, err := fs.ReadFile(assets.TplFs, path)
		if err != nil {
			log.Println("fs.ReadFile", err)
			return err
		}
		goTemplate := template.Must(template.New("").Parse(string(content)))
		return goTemplate.Execute(goFile, p)
	})

	return err
}
