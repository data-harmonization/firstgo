package main

import (
	"fmt"
	"os"

	"github.com/rubenv/sql-migrate"
	ms "sbp.gitlab.schubergphilis.com/api/microservice"
	"sbp.gitlab.schubergphilis.com/api/myservice/db"
	"sbp.gitlab.schubergphilis.com/api/myservice/service"
)

func main() {
	s, err := service.NewService(
		ms.WithServiceName("myservice"),
		ms.WithUsageMsg("Service to send messages to multiple channels (Mail, Slack, SMS and more)"),
		ms.WithAPIVersion("v1"),
		ms.WithRepository("https://sbp.gitlab.schubergphilis.com/api/myservice"),
		ms.WithSQL(true),
		ms.WithMigrationSource(&migrate.AssetMigrationSource{
			Asset:    db.Asset,
			AssetDir: db.AssetDir,
			Dir:      "db/migrations",
		}),
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Could not create the MyService Server: %v", err)
		os.Exit(1)
	}

	s.Run()
}
