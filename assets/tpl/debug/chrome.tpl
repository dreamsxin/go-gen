package debug

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"{{.PkgName}}/config"
	"{{.PkgName}}/logger"

	"github.com/chromedp/cdproto/network"
	"github.com/chromedp/cdproto/page"
	"github.com/chromedp/chromedp"
	"github.com/fsnotify/fsnotify"
	"go.uber.org/zap"
)

var ctx context.Context
var cancel context.CancelFunc

func InitDebug() {
	opts := []chromedp.ExecAllocatorOption{
		chromedp.Flag("no-first-run", true),
		chromedp.Flag("headless", false),
		chromedp.Flag("auto-open-devtools-for-tabs", true),
	}
	allocCtx, _ := chromedp.NewExecAllocator(context.Background(), opts...)

	ctx, cancel = chromedp.NewContext(allocCtx)
	if err := chromedp.Run(ctx, chromedp.Navigate("about:blank")); err != nil {
		log.Fatalln(err)
	}
	go OpenDevTools()
}

func OpenDevTools() {
	time.Sleep(time.Second * 1)
	host := config.Server().Host
	if host == "" || host == "0.0.0.0" {
		host = "localhost"
	}
	err := chromedp.Run(ctx,
		network.SetCacheDisabled(true),
		network.ClearBrowserCache(),
		chromedp.Navigate(fmt.Sprintf("http://%s:%d", host, config.Server().Port)),
	)
	if err != nil {
		logger.Error("chromedp.Run err", zap.Error(err))
	}
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	// 监听当前目录
	err = watcher.Add("./")
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()
	var lock sync.RWMutex
	for {
		select {
		case e, ok := <-watcher.Events:
			if !ok {
				return
			}
			if lock.TryLock() {
				logger.Debug("-------------TryLock------------------", e)
				err := chromedp.Run(ctx,
					network.SetCacheDisabled(true),
					network.ClearBrowserCache(),
					chromedp.ActionFunc(func(ctx context.Context) error {
						return page.Reload().WithIgnoreCache(true).Do(ctx)
					}),
				)
				if err != nil {
					logger.Error("chromedp.Run err", zap.Error(err))
				}
				logger.Debug("-------------Unlock------------------", e)
				lock.Unlock()
			}
		case _, ok := <-watcher.Errors:
			if !ok {
				return
			}
		}
	}
}
