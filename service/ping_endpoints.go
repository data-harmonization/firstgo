package service

import (
	"golang.org/x/net/context"
	pb "sbp.gitlab.schubergphilis.com/api/myservice/outputpb"
)

// PingMessage allows you to send an email to a list of recipients based on a template
func (s *Service) PingMessage(ctx context.Context, in *pb.Empty) (*pb.Response, error) {
	return &pb.Response{Message: "Hallo"}, nil
}
