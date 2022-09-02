package test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"strings"
	"testing"

	"github.com/otiai10/copy"
	"github.com/stretchr/testify/suite"
)

const DockerCmd = "run --rm -v=%s:/defs %s -f %s -l %s -i all/test/"

type FileExpectation struct {
	fileName      string
	assert        func(filePath string, expectedValue string)
	expectedValue string
}

type TestCase struct {
	lang              string
	protofileName     string
	expectedOutputDir string
	fileExpectations  []FileExpectation
	expectedExitCode  int
	extraArgs         []string
}

func (f *FileExpectation) Assert(filePath string) {
	if f.assert != nil {
		f.assert(filePath, f.expectedValue)
	}
}

type TestSuite struct {
	suite.Suite
}

func TestTestSuite(t *testing.T) {
	suite.Run(t, new(TestSuite))
}

func (s *TestSuite) SetupTest() {}

func (s *TestSuite) TestAllCases() {
	testCases := map[string]*TestCase{
		"go": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "/all/test_grpc.pb.go", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().False(strings.Contains(fileText, expectedValue), "contains \"%s\"", expectedValue)
				}, expectedValue: "func (UnimplementedMessageServer) mustEmbedUnimplementedMessageServer() {}"},
			},
		},
		"go with alternative output dir": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"ruby": {
			lang:              "ruby",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-ruby",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/test_pb.rb"},
				{fileName: "all/test/test_services_pb.rb"},
			},
		},
		"ruby with alternative output dir": {
			lang:              "ruby",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/test_pb.rb"},
				{fileName: "all/test/test_services_pb.rb"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"csharp": {
			lang:              "csharp",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-csharp",
			fileExpectations: []FileExpectation{
				{fileName: "Test.cs"},
				{fileName: "TestGrpc.cs"},
			},
		},
		"csharp with alternative output dir": {
			lang:              "csharp",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "Test.cs"},
				{fileName: "TestGrpc.cs"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"java": {
			lang:              "java",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-java",
			fileExpectations: []FileExpectation{
				{fileName: "Messages/Test.java"},
				{fileName: "Messages/MessageGrpc.java"},
			},
		},
		"java with alternative output dir": {
			lang:              "java",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "Messages/Test.java"},
				{fileName: "Messages/MessageGrpc.java"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"python": {
			lang:              "python",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb_python",
			fileExpectations: []FileExpectation{
				{fileName: "/__init__.py"},
				{fileName: "/all/__init__.py"},
				{fileName: "/all/test/__init__.py"},
				{fileName: "/all/test/test_pb2.py"},
				{fileName: "/all/test/test_pb2_grpc.py"},
			},
		},
		"python pyi": {
			lang:              "python",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb_python",
			fileExpectations: []FileExpectation{
				{fileName: "/__init__.py"},
				{fileName: "/all/__init__.py"},
				{fileName: "/all/test/__init__.py"},
				{fileName: "/all/test/test_pb2.py"},
				{fileName: "/all/test/test_pb2.pyi"},
				{fileName: "/all/test/test_pb2_grpc.py"},
				{fileName: "/all/test/test_pb2_grpc.pyi"},
			},
			extraArgs: []string{"--with-pyi"},
		},
		"python pyi with inconsistent language parameter": {
			lang:             "ruby",
			protofileName:    "all/test/test.proto",
			expectedExitCode: 1,
			extraArgs:        []string{"--with-pyi"},
		},
		"python with alternative output dir": {
			lang:              "python",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "/__init__.py"},
				{fileName: "/all/__init__.py"},
				{fileName: "/all/test/__init__.py"},
				{fileName: "/all/test/test_pb2.py"},
				{fileName: "/all/test/test_pb2_grpc.py"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"objc": {
			lang:              "objc",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-objc",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/Test.pbobjc.h"},
				{fileName: "all/test/Test.pbobjc.m"},
				{fileName: "all/test/Test.pbrpc.h"},
				{fileName: "all/test/Test.pbrpc.m"},
			},
		},
		"objc with alternative output dir": {
			lang:              "objc",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/Test.pbobjc.h"},
				{fileName: "all/test/Test.pbobjc.m"},
				{fileName: "all/test/Test.pbrpc.h"},
				{fileName: "all/test/Test.pbrpc.m"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"node": {
			lang:              "node",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-node",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_grpc_pb.js"},
				{fileName: "/all/test/test_pb.js"},
			},
		},
		"node with alternative output dir": {
			lang:              "node",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_grpc_pb.js"},
				{fileName: "/all/test/test_pb.js"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"gogo": {
			lang:              "gogo",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-gogo",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
			},
		},
		"gogo with alternative output dir": {
			lang:              "gogo",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"gogo with validator": {
			lang:              "gogo",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-gogo",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test.pb.validate.go"},
			},
			extraArgs: []string{"--with-validator"},
		},
		"php": {
			lang:              "php",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-php",
			fileExpectations: []FileExpectation{
				{fileName: "/GPBMetadata/All/Test/Test.php"},
				{fileName: "/Messages/ListMessageRequest.php"},
				{fileName: "/Messages/MessageClient.php"},
				{fileName: "/Messages/UnboundUnaryRequest.php"},
				{fileName: "/Messages/UnboundUnaryResponse.php"},
				{fileName: "/Messages/UpdateMessageRequest.php"},
				{fileName: "/Messages/UpdateMessageResponse.php"},
			},
		},
		"php with alternative output dir": {
			lang:              "php",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "/GPBMetadata/All/Test/Test.php"},
				{fileName: "/Messages/ListMessageRequest.php"},
				{fileName: "/Messages/MessageClient.php"},
				{fileName: "/Messages/UnboundUnaryRequest.php"},
				{fileName: "/Messages/UnboundUnaryResponse.php"},
				{fileName: "/Messages/UpdateMessageRequest.php"},
				{fileName: "/Messages/UpdateMessageResponse.php"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"cpp": {
			lang:              "cpp",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-cpp",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test.grpc.pb.cc"},
				{fileName: "/all/test/test.grpc.pb.h"},
				{fileName: "/all/test/test.pb.cc"},
				{fileName: "/all/test/test.pb.h"},
			},
		},
		"cpp with alternative output dir": {
			lang:              "cpp",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test.grpc.pb.cc"},
				{fileName: "/all/test/test.grpc.pb.h"},
				{fileName: "/all/test/test.pb.cc"},
				{fileName: "/all/test/test.pb.h"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"descriptor_set": {
			lang:              "descriptor_set",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-descriptor_set",
			fileExpectations: []FileExpectation{
				{fileName: "/descriptor_set.pb"},
			},
		},
		"descriptor_set with alternative output dir": {
			lang:              "descriptor_set",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "/descriptor_set.pb"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"web": {
			lang:              "web",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-web",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_pb.d.ts"},
				{fileName: "/all/test/test_pb.js"},
				{fileName: "/all/test/TestServiceClientPb.ts"},
			},
		},
		"web with alternative output dir": {
			lang:              "web",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_pb.d.ts"},
				{fileName: "/all/test/test_pb.js"},
				{fileName: "/all/test/TestServiceClientPb.ts"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"go with html docs": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
				{fileName: "/doc/index.html"},
			},
			extraArgs: []string{"--with-docs"},
		},
		"go with markdown docs": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
				{fileName: "/doc/index.md"},
			},
			extraArgs: []string{"--with-docs", "markdown,index.md"},
		},
		"go with gateway": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
				{fileName: "/all/test.pb.gw.go", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().False(strings.Contains(fileText, expectedValue), "contains \"%s\"", expectedValue)
				}, expectedValue: "UnboundUnary",
				},
				{fileName: "/all/test/test.swagger.json"},
			},
			extraArgs: []string{"--with-gateway"},
		},
		"go with gateway and source_relative": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/test.pb.go"},
				{fileName: "/all/test/test.pb.gw.go", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().False(strings.Contains(fileText, expectedValue), "contains \"%s\"", expectedValue)
				}, expectedValue: "UnboundUnary",
				},
				{fileName: "/all/test/test.swagger.json"},
			},
			extraArgs: []string{"--with-gateway", "--go-source-relative"},
		},
		"go with gateway and json": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
				{fileName: "/all/test.pb.gw.go"},
				{fileName: "/all/test/test.swagger.json", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().True(strings.Contains(fileText, expectedValue), "does not contain \"%s\"", expectedValue)
				}, expectedValue: "additionalParam"},
				{fileName: "/all/test/test.swagger.json", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					var anyJSON map[string]interface{}
					err := json.Unmarshal([]byte(fileText), &anyJSON)
					s.Require().NoError(err)
					jsonPath := "definitions.MessagesUpdateMessageRequest.properties.updateMask"
					fields := strings.Split(jsonPath, ".")
					m := anyJSON
					var ok bool
					for _, field := range fields {
						m, ok = m[field].(map[string]interface{})
						s.Require().True(ok)
					}
					s.Assert().Equal(expectedValue, m["type"])
				}, expectedValue: "array"},
			},
			extraArgs: []string{"--with-gateway", "--with-openapi-json-names"},
		},
		"go with gateway and json (deprecated flag)": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
				{fileName: "/all/test.pb.gw.go"},
				{fileName: "/all/test/test.swagger.json", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().True(strings.Contains(fileText, expectedValue), "does not contain \"%s\"", expectedValue)
				}, expectedValue: "additionalParam"},
			},
			extraArgs: []string{"--with-gateway", "--with-swagger-json-names"},
		},
		"go with gateway and unbound methods": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "all/test.pb.go"},
				{fileName: "all/test_grpc.pb.go"},
				{fileName: "/all/test.pb.gw.go", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().True(strings.Contains(fileText, expectedValue), "does not contain \"%s\"", expectedValue)
				}, expectedValue: "UnboundUnary"},
				{fileName: "/all/test/test.swagger.json"},
			},
			extraArgs: []string{"--with-gateway", "--generate-unbound-methods"},
		},
		"go with source_relative": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test.pb.go"},
				{fileName: "/all/test/test_grpc.pb.go"},
			},
			extraArgs: []string{"--go-source-relative"},
		},
		"go with module_prefixes": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/test.pb.go"},
				{fileName: "/test_grpc.pb.go"},
			},
			extraArgs: []string{"--go-module-prefix", "all"},
		},
		"go with source_relative and module_prefix #1": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			expectedExitCode:  1,
			extraArgs:         []string{"--go-module-prefix", "all", "--go-source-relative"},
		},
		"go with source_relative and module_prefix #2": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			expectedExitCode:  1,
			extraArgs:         []string{"--go-source-relative", "--go-module-prefix", "all"},
		},
		"go with validator": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test.pb.go"},
				{fileName: "/all/test_grpc.pb.go"},
				{fileName: "/all/test.pb.validate.go"},
			},
			extraArgs: []string{"--with-validator"},
		},
		"go with validator and optional field": {
			lang:              "go",
			protofileName:     "all/test/test_optional.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test_optional.pb.go"},
				{fileName: "/all/test_optional.pb.validate.go"},
			},
			extraArgs: []string{"--with-validator"},
		},
		"go with validator and source_relative": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test.pb.go"},
				{fileName: "/all/test_grpc.pb.go"},
				{fileName: "/all/test/test.pb.validate.go"},
			},
			extraArgs: []string{"--with-validator", "--validator-source-relative"},
		},
		"go with proto_validator": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test.pb.go"},
				{fileName: "/all/test_grpc.pb.go"},
				{fileName: "/all/test.validator.pb.go"},
			},
			extraArgs: []string{"--go-proto-validator"},
		},
		"go with require-unimplemented-servers": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test.pb.go"},
				{fileName: "/all/test_grpc.pb.go", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().True(strings.Contains(fileText, expectedValue), "does not contain \"%s\"", expectedValue)
				}, expectedValue: "func (UnimplementedMessageServer) mustEmbedUnimplementedMessageServer() {}"},
			},
			extraArgs: []string{"--go-grpc-require-unimplemented-servers"},
		},
		"go micro": {
			lang:              "go",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-go",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test.pb.go"},
				{fileName: "/all/test.pb.micro.go"},
			},
			extraArgs: []string{"--go-plugin-micro"},
		},
		"ruby rbi": {
			lang:              "ruby",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-ruby",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_pb.rb"},
				{fileName: "/all/test/test_pb.rbi"},
				{fileName: "/all/test/test_services_pb.rb"},
				{fileName: "/all/test/test_services_pb.rbi"},
			},
			extraArgs: []string{"--with-rbi"},
		},
		"node with typescript": {
			lang:              "node",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-node",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_grpc_pb.d.ts"},
				{fileName: "/all/test/test_grpc_pb.js"},
				{fileName: "/all/test/test_pb.d.ts"},
				{fileName: "/all/test/test_pb.js"},
			},
			extraArgs: []string{"--with-typescript"},
		},
		"node with alternative imports": {
			lang:              "node",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-node",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_grpc_pb.js"},
				{fileName: "testlib.js"},
			},
			extraArgs: []string{"--js-out", "library=testlib"},
		},
		"node with grpc_out": {
			lang:              "node",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-node",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_grpc_pb.js"},
				{fileName: "/all/test/test_pb.js"},
			},
			extraArgs: []string{"--grpc-out", "grpc-js"},
		},
		"web with typescript imports": {
			lang:              "web",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-web",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_pb.d.ts"},
				{fileName: "/all/test/test_pb.js"},
				{fileName: "/all/test/TestServiceClientPb.ts"},
			},
			extraArgs: []string{"--grpc-web-out", "import_style=typescript"},
		},
		"web with commonjs imports": {
			lang:              "web",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-web",
			fileExpectations: []FileExpectation{
				{fileName: "/all/test/test_grpc_web_pb.d.ts"},
				{fileName: "/all/test/test_grpc_web_pb.js"},
				{fileName: "/all/test/test_pb.d.ts"},
				{fileName: "/all/test/test_pb.js"},
			},
			extraArgs: []string{"--grpc-web-out", "import_style=commonjs+dts"},
		},
		"java test jar": {
			lang:              "java",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen",
			fileExpectations: []FileExpectation{
				{fileName: "test.jar"},
			},
			extraArgs: []string{"-o", "gen/test.jar"},
		},
		"java with validator": {
			lang:              "java",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-java",
			fileExpectations: []FileExpectation{
				{fileName: "Messages/MessageGrpc.java"},
				{fileName: "Messages/Test.java"},
				{fileName: "Messages/TestValidator.java"},
			},
			extraArgs: []string{"--with-validator"},
		},
		"typescript": {
			lang:              "typescript",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-typescript",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/test.ts"},
			},
		},
		"typescript with alternative output dir": {
			lang:              "typescript",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/foo/bar",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/test.ts", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().True(strings.Contains(fileText, expectedValue), "does not contain \"%s\"", expectedValue)
					// without useOptionals=messages uses `string[] | undefined` syntax. by default.
				}, expectedValue: "updateMask: string[] | undefined;"},
			},
			extraArgs: []string{"-o", "gen/foo/bar"},
		},
		"typescript with arguments": {
			lang:              "typescript",
			protofileName:     "all/test/test.proto",
			expectedOutputDir: "gen/pb-typescript",
			fileExpectations: []FileExpectation{
				{fileName: "all/test/test.ts", assert: func(filePath, expectedValue string) {
					fileText := s.readFile(filePath)
					s.Assert().True(strings.Contains(fileText, expectedValue), "does not contain \"%s\"", expectedValue)
					// useOptionals=messages changes `updateMask: string[] | undefined` to `updateMask?: string[]`
				}, expectedValue: "updateMask?: string[];"},
			},
			extraArgs: []string{"--ts_opt", "useOptionals=messages"},
		},
	}
	container := os.Getenv("CONTAINER")
	s.Require().NotEmpty(container, "CONTAINER env var must be set")
	wd, err := os.Getwd()
	s.Require().NoError(err)
	wd = path.Join(wd, "..", "..")
	opt := copy.Options{
		Skip: func(src string) (bool, error) {
			res := !(path.Base(src) == "test" || strings.HasSuffix(src, ".proto"))
			return res, nil
		},
	}
	src := path.Join(wd, "all")
	for name, testCase := range testCases {
		func(name string, testCase *TestCase) {
			s.Run(name, func() {
				s.T().Parallel()
				dir, err := ioutil.TempDir(wd, strings.ReplaceAll(name, " ", "_")+"_")
				defer os.RemoveAll(dir)
				s.Require().NoError(err)
				err = copy.Copy(src, path.Join(dir, "all"), opt)
				argsStr := fmt.Sprintf(DockerCmd,
					dir,
					container,
					testCase.protofileName,
					testCase.lang,
				)
				exitCode := s.executeDocker(argsStr, testCase.extraArgs...)
				s.Require().Equal(testCase.expectedExitCode, exitCode)
				for _, fileExpectation := range testCase.fileExpectations {
					fileFullPath := path.Join(dir, testCase.expectedOutputDir, fileExpectation.fileName)
					s.Assert().FileExists(fileFullPath)
					fileExpectation.Assert(fileFullPath)
				}
			})
		}(name, testCase)
	}
}

func (s *TestSuite) executeDocker(argsStr string, extraArgs ...string) int {
	args := append(strings.Split(argsStr, " "), extraArgs...)
	cmd := exec.Command("docker", args...)
	err := cmd.Run()
	if err != nil {
		exitError, ok := err.(*exec.ExitError)
		s.Require().True(ok)
		return exitError.ExitCode()
	}
	return 0
}

func (s *TestSuite) readFile(file string) string {
	b, err := ioutil.ReadFile(file)
	s.Require().NoError(err)
	return string(b)
}
