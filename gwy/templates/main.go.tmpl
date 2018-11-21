package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/textproto"
	"os"
	"os/signal"
	"strings"
	"time"

	"github.com/gorilla/handlers"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/sirupsen/logrus"
	"github.com/spf13/pflag"
	"github.com/spf13/viper"
	"golang.org/x/net/context"
	"google.golang.org/grpc"

	gw "gen/pb-go"
)

type proxyConfig struct {
	// The backend gRPC service to listen to.
	backend string
	// The log level to use
	logLevel string
	// Whether to log request headers
	logHeaders bool
	// Path to the swagger file to serve.
	swagger string
	// Value to set for Access-Control-Allow-Origin header.
	corsAllowOrigin string
	// Value to set for Access-Control-Allow-Credentials header.
	corsAllowCredentials string
	// Value to set for Access-Control-Allow-Methods header.
	corsAllowMethods string
	// Value to set for Access-Control-Allow-Headers header.
	corsAllowHeaders string
	// Prefix that this gateway is running on. For example, if your API endpoint
	// was "/foo/bar" in your protofile, and you wanted to run APIs under "/api",
	// set this to "/api/".
	apiPrefix string
}

func logFormatter(cfg proxyConfig) handlers.LogFormatter {

	// Setup logrus
	logrus.SetFormatter(&logrus.JSONFormatter{
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime: "@timestamp",
		},
	})
	level, err := logrus.ParseLevel(cfg.logLevel)
	if err != nil {
		logrus.SetLevel(logrus.InfoLevel)
	} else {
		logrus.SetLevel(level)
	}

	return func(writer io.Writer, params handlers.LogFormatterParams) {

		host, _, err := net.SplitHostPort(params.Request.RemoteAddr)
		if err != nil {
			host = params.Request.RemoteAddr
		}

		uri := params.Request.RequestURI

		// Requests using the CONNECT method over HTTP/2.0 must use
		// the authority field (aka r.Host) to identify the target.
		// Refer: https://httpwg.github.io/specs/rfc7540.html#CONNECT
		if params.Request.ProtoMajor == 2 && params.Request.Method == "CONNECT" {
			uri = params.Request.Host
		}
		if uri == "" {
			uri = params.URL.RequestURI()
		}

		duration := int64(time.Now().Sub(params.TimeStamp) / time.Millisecond)

		fields := logrus.Fields{
			"host":       host,
			"url":        uri,
			"duration":   duration,
			"status":     params.StatusCode,
			"method":     params.Request.Method,
			"request":    params.Request.RequestURI,
			"remote":     params.Request.RemoteAddr,
			"size":       params.Size,
			"referer":    params.Request.Referer(),
			"user_agent": params.Request.UserAgent(),
			"request_id": params.Request.Header.Get("x-request-id"),
		}

		// Only append headers if explicitly enabled
		if cfg.logHeaders {
			if headers, err := json.Marshal(params.Request.Header); err == nil {
				fields["headers"] = string(headers)
			} else {
				fields["header_error"] = err.Error()
			}
		}

		logrus.WithFields(fields).WithTime(params.TimeStamp).Infof("%s %s %d", params.Request.Method, uri, params.StatusCode)
	}
}

func allowCors(cfg proxyConfig, handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		corsAllowOrigin := cfg.corsAllowOrigin
		if corsAllowOrigin == "*" {
			if origin := req.Header.Get("Origin"); origin != "" {
				corsAllowOrigin = origin
			}
		}
		w.Header().Set("Access-Control-Allow-Origin", corsAllowOrigin)
		w.Header().Set("Access-Control-Allow-Credentials", cfg.corsAllowCredentials)
		w.Header().Set("Access-Control-Allow-Methods", cfg.corsAllowMethods)
		w.Header().Set("Access-Control-Allow-Headers", cfg.corsAllowHeaders)
		if req.Method == "OPTIONS" && req.Header.Get("Access-Control-Request-Method") != "" {
			return
		}
		handler.ServeHTTP(w, req)
	})
}

// sanitizeApiPrefix forces prefix to be non-empty and end with a slash.
func sanitizeApiPrefix(prefix string) string {
	if len(prefix) == 0 || prefix[len(prefix)-1:] != "/" {
		return prefix + "/"
	}
	return prefix
}

// isPermanentHTTPHeader checks whether hdr belongs to the list of
// permenant request headers maintained by IANA.
// http://www.iana.org/assignments/message-headers/message-headers.xml
// From https://github.com/grpc-ecosystem/grpc-gateway/blob/7a2a43655ccd9a488d423ea41a3fc723af103eda/runtime/context.go#L157
func isPermanentHTTPHeader(hdr string) bool {
	switch hdr {
	case
		"Accept",
		"Accept-Charset",
		"Accept-Language",
		"Accept-Ranges",
		"Authorization",
		"Cache-Control",
		"Content-Type",
		"Cookie",
		"Date",
		"Expect",
		"From",
		"Host",
		"If-Match",
		"If-Modified-Since",
		"If-None-Match",
		"If-Schedule-Tag-Match",
		"If-Unmodified-Since",
		"Max-Forwards",
		"Origin",
		"Pragma",
		"Referer",
		"User-Agent",
		"Via",
		"Warning":
		return true
	}
	return false
}

// isReserved returns whether the key is reserved by gRPC.
func isReserved(key string) bool {
	return strings.HasPrefix(key, "Grpc-")
}

// incomingHeaderMatcher converts an HTTP header name on http.Request to
// grpc metadata. Permanent headers (i.e. User-Agent) are prepended with
// "grpc-gateway". Headers that start with start with "Grpc-" (reserved
// by grpc) are prepended with "X-". Other headers are forwarded as is.
func incomingHeaderMatcher(key string) (string, bool) {
	key = textproto.CanonicalMIMEHeaderKey(key)
	if isPermanentHTTPHeader(key) {
		return runtime.MetadataPrefix + key, true
	}
	if isReserved(key) {
		return "X-" + key, true
	}

	// The Istio service mesh dislikes when you pass the Content-Length header
	if key == "Content-Length" {
		return "", false
	}

	return key, true
}

// outgoingHeaderMatcher transforms outgoing metadata into HTTP headers.
// We return any response metadata as is.
func outgoingHeaderMatcher(metadata string) (string, bool) {
	return metadata, true
}

func SetupMux(ctx context.Context, cfg proxyConfig) *http.ServeMux {

	formatter := logFormatter(cfg)

	logrus.Infof("Creating grpc-gateway proxy with config: %v", cfg)
	mux := http.NewServeMux()

	mux.HandleFunc("/swagger.json", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, cfg.swagger)
	})

	gwmux := runtime.NewServeMux(
		runtime.WithIncomingHeaderMatcher(incomingHeaderMatcher),
		runtime.WithOutgoingHeaderMatcher(outgoingHeaderMatcher),
	)
	logrus.Infof("Proxying requests to gRPC service at '%s'", cfg.backend)

	opts := []grpc.DialOption{grpc.WithInsecure()}
	// If you get a compilation error that gw.Register${SERVICE}HandlerFromEndpoint
	// does not exist, it's because you haven't added any google.api.http annotations
	// to your proto. Add some!
	err := gw.Register${SERVICE}HandlerFromEndpoint(ctx, gwmux, cfg.backend, opts)
	if err != nil {
		logrus.Fatalf("Could not register gateway: %v", err)
	}

	prefix := sanitizeApiPrefix(cfg.apiPrefix)
	logrus.Infof("API prefix is: %s", prefix)
	mux.Handle(prefix, handlers.CustomLoggingHandler(os.Stdout, http.StripPrefix(prefix[:len(prefix)-1], allowCors(cfg, gwmux)), formatter))
	return mux
}

// SetupViper returns a viper configuration object
func SetupViper() *viper.Viper {
	viper.SetConfigName("config")
	viper.AddConfigPath(".")
	viper.SetEnvPrefix("${SERVICE}")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	flag.String("backend", "", "The gRPC backend service to proxy.")

	pflag.CommandLine.AddGoFlagSet(flag.CommandLine)
	pflag.Parse()
	viper.BindPFlags(pflag.CommandLine)

	err := viper.ReadInConfig()
	if err != nil {
		logrus.Fatalf("Could not read config: %v", err)
	}

	return viper.GetViper()
}

// SignalRunner runs a runner function until an interrupt signal is received, at which point it
// will call stopper.
func SignalRunner(runner, stopper func()) {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt, os.Kill)

	go func() {
		runner()
	}()

	logrus.Info("hit Ctrl-C to shutdown")
	select {
	case <-signals:
		stopper()
	}
}

func main() {

	cfg := SetupViper()
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	mux := SetupMux(ctx, proxyConfig{
		backend:              cfg.GetString("backend"),
		logLevel:             cfg.GetString("log_level"),
		logHeaders:           cfg.GetBool("log_headers"),
		swagger:              cfg.GetString("swagger.file"),
		corsAllowOrigin:      cfg.GetString("cors.allow-origin"),
		corsAllowCredentials: cfg.GetString("cors.allow-credentials"),
		corsAllowMethods:     cfg.GetString("cors.allow-methods"),
		corsAllowHeaders:     cfg.GetString("cors.allow-headers"),
		apiPrefix:            cfg.GetString("proxy.api-prefix"),
	})

	addr := fmt.Sprintf(":%v", cfg.GetInt("proxy.port"))
	server := &http.Server{Addr: addr, Handler: mux}

	SignalRunner(
		func() {
			logrus.Infof("launching http server on %v", server.Addr)
			if err := server.ListenAndServe(); err != nil {
				logrus.Fatalf("Could not start http server: %v", err)
			}
		},
		func() {
			shutdown, _ := context.WithTimeout(ctx, 10*time.Second)
			server.Shutdown(shutdown)
		})
}
