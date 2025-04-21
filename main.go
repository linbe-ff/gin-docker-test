package main

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// 1.创建路由
	r := gin.Default()
	// 2.绑定路由规则，执行的函数
	// gin.Context，封装了request和response
	logpath := "app\\log\\"
	r.GET("/", func(c *gin.Context) {

		it := new(interface{})

		shouldBind := c.ShouldBind(&it)
		fmt.Println(it)
		fmt.Println(shouldBind)

		os.WriteFile(logpath+"log"+time.Now().Format("2006-01-02 15:04:05")+".log",
			[]byte("有吊毛调接口了"+time.Now().Format("2006-01-02 15:04:05")), 0644)
		c.String(http.StatusOK, "部署到docker")
	})
	// 3.监听端口，默认在8080
	// Run("里面不指定端口号默认为8080")
	r.Run(":8001")
	os.WriteFile(logpath+"log"+time.Now().Format("2006-01-02 15:04:05")+".log", []byte("程序启动：端口："+strconv.Itoa(8001)), 0644)
}
