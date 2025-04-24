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
	logpath := "/app/logs/"
	r.GET("/", func(c *gin.Context) {

		it := new(interface{})

		shouldBind := c.ShouldBind(&it)
		fmt.Println(it)
		fmt.Println(shouldBind)

		file, err := os.OpenFile(logpath+"log"+time.Now().Format("2006-01-02")+".log",
			os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			fmt.Println("打开日志文件失败:", err)
			return
		}
		defer file.Close()

		if _, err := file.WriteString("有吊毛调接口了" + time.Now().Format("2006-01-02 15:04:05") + "\n"); err != nil {
			fmt.Println("写入日志失败:", err)
		}
		c.String(http.StatusOK, "部署到docker")
	})
	// 3.监听端口，默认在8080
	// Run("里面不指定端口号默认为8080")
	r.Run(":8002")
	os.WriteFile(logpath+"log"+time.Now().Format("2006-01-02 15:04:05")+".log", []byte("程序启动：端口："+strconv.Itoa(8001)), 0644)
}
