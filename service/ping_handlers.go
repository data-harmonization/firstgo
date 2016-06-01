package service

import (
	"net/http"

	"golang.org/x/net/context"
	ms "sbp.gitlab.schubergphilis.com/api/microservice"
	pb "sbp.gitlab.schubergphilis.com/api/myservice/outputpb"
)

func makePingHandler(s pb.MyServiceServer) http.Handler {
	return ms.RESTHandler(
		func(ctx context.Context, w http.ResponseWriter, r *http.Request) (interface{}, error) {
			return s.PingMessage(ctx, &pb.Empty{})
		},
	)
}
