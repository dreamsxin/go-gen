package services

import (
	"{{.PkgName}}/base"
)

type UserService struct {
	*base.BaseService
}

var SerUser = UserService{
	base.NewService("hello"),
}
