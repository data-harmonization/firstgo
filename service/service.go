package service

import (
	"net/http"

	"github.com/serenize/snaker"
	"sbp.gitlab.schubergphilis.com/api/authservice/authpb"
	ms "sbp.gitlab.schubergphilis.com/api/microservice"
	ds "sbp.gitlab.schubergphilis.com/api/microservice/discovery"
	"sbp.gitlab.schubergphilis.com/api/microservice/storage"
	pb "sbp.gitlab.schubergphilis.com/api/myservice/outputpb"
)

// Service defines the calendarservice
type Service struct {
	Config *Config
	Server ms.Server

	authClient authpb.AuthServiceClient
}

// Config represents the configuration.
type Config struct {
	*ms.Config
}

// NewService is the constructor of main Service Server
func NewService(opts ...ms.Option) (*Service, error) {
	// Create a microservice Server which our server will embed
	server, err := ms.NewServer(opts...)
	if err != nil {
		return nil, err
	}

	cfg := &Config{Config: server.Config()}

	s := &Service{
		Config: cfg,
		Server: server,
	}
	return s, nil
}

// Run configures the server and then calls ServeAndWait
func (s *Service) Run() {
	s.Server.RunAndServe(s.Configure)
}

// Configure is run after the cli has been initialized and the configuration has been set
func (s *Service) Configure(server ms.Server) error {
	db, err := storage.NewDBX(s.Config.SQLDriver, s.Config.DSN)
	if err != nil {
		return err
	}

	db.MapperFunc(snaker.CamelToSnake)

	server.NewCheck("database", storage.Check(db))

	f := ds.NewFactory(
		ds.WithEtcdDirectory(s.Config.Etcd.Directory),
		ds.WithEtcdEndpoints(s.Config.Etcd.Endpoints),
		ds.WithOverrides(s.Config.DiscoveryOverrides),
	)

	// Create grpc clients to other services:
	conn, err := f.Connection("authservice", "v1")
	if err != nil {
		return err
	}

	s.authClient = authpb.NewAuthServiceClient(conn)

	pb.RegisterMyServiceServer(server.RPCTransport().Server, s)

	server.NewRoute(http.MethodGet, "/ping", makePingHandler(s))

	return nil
}
