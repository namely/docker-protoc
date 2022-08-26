#!/bin/bash
set -e

printUsage() {
    echo "gen-proto generates grpc and protobuf @ Namely"
    echo " "
    echo "Usage: gen-proto -f my-service.proto -l go"
    echo " "
    echo "options:"
    echo " -h, --help                                       Show help"
    echo " -f FILE                                          The proto source file to generate"
    echo " -d DIR                                           Scans the given directory for all proto files"
    echo " -l LANGUAGE                                      The language to generate (${SUPPORTED_LANGUAGES[@]})"
    echo " -o DIRECTORY                                     The output directory for generated files. Will be automatically created."
    echo " -i includes                                      Extra includes"
    echo " --lint CHECKS                                    Enable linting protoc-lint (CHECKS are optional - see https://github.com/ckaznocha/protoc-gen-lint#optional-checks)"
    echo " --with-gateway                                   Generate grpc-gateway files (experimental)."
    echo " --with-docs FORMAT                               Generate documentation (FORMAT is optional - see https://github.com/pseudomuto/protoc-gen-doc#invoking-the-plugin)"
    echo " --with-rbi                                       Generate Sorbet type declaration files (.rbi files) - see https://github.com/coinbase/protoc-gen-rbi"
    echo " --with-typescript                                Generate TypeScript declaration files (.d.ts files) - see https://github.com/improbable-eng/ts-protoc-gen#readme"
    echo " --with-validator                                 Generate validations for (${VALIDATOR_SUPPORTED_LANGUAGES[@]}) - see https://github.com/envoyproxy/protoc-gen-validate"
    echo " --validator-source-relative                      Make the output dirctory for protoc-gen-validate 'source relative' - see https://github.com/envoyproxy/protoc-gen-validate#go"
    echo " --go-source-relative                             Make go import paths 'source_relative' - see https://github.com/golang/protobuf#parameters"
    echo " --go-module-prefix                               Specify the module prefix to remove from the import path - see https://developers.google.com/protocol-buffers/docs/reference/go-generated#invocation"
    echo " --go-package-map                                 Map proto imports to go import paths"
    echo " --go-plugin-micro                                Replaces the Go gRPC plugin with go-micro"
    echo " --go-proto-validator                             Generate Go proto validations - see https://github.com/mwitkow/go-proto-validators"
    echo " --go-grpc-require-unimplemented-servers          Generate Go gRPC service with unimplemented server for future compatability- https://github.com/grpc/grpc-go/tree/master/cmd/protoc-gen-go-grpc#future-proofing-services"
    echo " --no-google-includes                             Don't include Google protobufs"
    echo " --descr-include-imports                          When using --descriptor_set_out, also include all dependencies of the input files in the set, so that the set is self-contained"
    echo " --descr-include-source-info                      When using --descriptor_set_out, do not strip SourceCodeInfo from the FileDescriptorProto. This results in vastly
                                                            larger descriptors that include information about the original location of each decl in the source file as  well
                                                            as surrounding comments."
    echo " --descr-filename                                 The filename for the descriptor proto when used with -l descriptor_set. Default to descriptor_set.pb"
    echo " --csharp_opt                                     The options to pass to protoc to customize the csharp code generation."
    echo " --scala_opt                                      The options to pass to protoc to customize the scala code generation."
    echo " --with-swagger-json-names                        Use with --with-gateway flag. Generated swagger file will use JSON names instead of protobuf names.
                                                            (deprecated. Please use --with-openapi-json-names)"
    echo " --with-openapi-json-names                        Use with --with-gateway flag. Generated OpenAPI file will use JSON names instead of protobuf names."
    echo " --generate-unbound-methods                       Use with --with-gateway flag. Produce the HTTP mapping even for methods without any HttpRule annotation."
    echo " --js-out                                         This option overrides the 'js_out=' argument in the grpc-node and grpc-web code generation. Defaults to 'import_style=commonjs'."
    echo " --grpc-out                                       This option allows overriding the left-half of the 'grpc_out=' argument (before the colon) with grpc-node and grpc-web code generation. Options are: generate_package_definition, grpc_js or grpc(depricated from April 2021). Defaults to grpc_js."
    echo " --grpc-web-out                                   This option overrides the 'grpc-web_out=' argument in the grpc-web code generation.  Defaults to 'import_style=typescript'."
    echo " --ts_opt                                         The options to pass to protoc to customize the typescript code generation. See https://github.com/stephenh/ts-proto#supported-options. --ts_opt useOptionals=messages will evaluate to --ts_proto_opt=useOptionals=messages"
}

GEN_GATEWAY=false
GEN_DOCS=false
GEN_VALIDATOR=false
VALIDATOR_SUPPORTED_LANGUAGES=("go" "gogo" "cpp" "java" "python")
DOCS_FORMAT="html,index.html"
GEN_RBI=false
GEN_TYPESCRIPT=false
LINT=false
LINT_CHECKS=""
SUPPORTED_LANGUAGES=("go" "ruby" "csharp" "java" "python" "objc" "gogo" "php" "node" "typescript" "web" "cpp" "descriptor_set" "scala")
EXTRA_INCLUDES=""
OUT_DIR=""
GO_SOURCE_RELATIVE=""
GO_MODULE_PREFIX=""
GO_PACKAGE_MAP=""
GO_PLUGIN="grpc"
GO_VALIDATOR=false
GO_GRPC_REQUIRE_UNIMPLEMENTED_SERVERS="require_unimplemented_servers=false"
NO_GOOGLE_INCLUDES=false
DESCR_INCLUDE_IMPORTS=false
DESCR_INCLUDE_SOURCE_INFO=false
DESCR_FILENAME="descriptor_set.pb"
CSHARP_OPT=""
SCALA_OPT=""
OPENAPI_JSON=false
GENERATE_UNBOUND_METHODS=false
JS_OUT="import_style=commonjs"
WEB_OUT="import_style=typescript"
GRPC_OUT="grpc_js"
TYPESCRIPT_OPT=""
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            printUsage
            exit 0
            ;;
        -f)
            shift
            if test $# -gt 0; then
                FILE=$1
            else
                echo "no input file specified"
                exit 1
            fi
            shift
            ;;
        -d)
            shift
            if test $# -gt 0; then
                PROTO_DIR=$1
            else
                echo "no directory specified"
                exit 1
            fi
            shift
            ;;
        -l)
            shift
            if test $# -gt 0; then
                GEN_LANG=$1
            else
                echo "no language specified"
                exit 1
            fi
            shift
            ;;
        -o) shift
            OUT_DIR=$1
            shift
            ;;
        -i) shift
            EXTRA_INCLUDES="$EXTRA_INCLUDES -I$1"
            shift
            ;;
        --with-gateway)
            GEN_GATEWAY=true
            shift
            ;;
        --with-docs)
            GEN_DOCS=true
            if [ "$#" -gt 1 ] && [[ $2 != -* ]]; then
                DOCS_FORMAT=$2
                shift
            fi
            shift
            ;;
        --with-rbi)
            GEN_RBI=true
            shift
            ;;
        --with-typescript)
            GEN_TYPESCRIPT=true
            shift
            ;;
        --with-validator)
            GEN_VALIDATOR=true
            shift
            ;;
        --lint)
            LINT=true
            if [ "$#" -gt 1 ] && [[ $2 != -* ]]; then
                LINT_CHECKS=$2
            shift
            fi
            shift
            ;;
        --validator-source-relative)
            VALIDATOR_SOURCE_RELATIVE=",paths=source_relative"
            shift
            ;;
        --go-source-relative)
            GO_SOURCE_RELATIVE="paths=source_relative,"
            shift
            ;;
        --go-module-prefix)
            shift
            GO_MODULE_PREFIX="module=$1,"
            shift
            ;;
        --go-package-map)
            if [ "$#" -gt 1 ] && [[ $2 != -* ]]; then
                GO_PACKAGE_MAP=$2,
            shift
            fi
            shift
            ;;
        --go-plugin-micro)
            GO_PLUGIN="micro"
            shift
            ;;
        --go-proto-validator)
            GO_VALIDATOR=true
            shift
            ;;
        --go-grpc-require-unimplemented-servers)
            GO_GRPC_REQUIRE_UNIMPLEMENTED_SERVERS="require_unimplemented_servers=true"
            shift
            ;;
        --no-google-includes)
            NO_GOOGLE_INCLUDES=true
            shift
            ;;
        --descr-include-imports)
            DESCR_INCLUDE_IMPORTS=true
            shift
            ;;
        --descr-include-source-info)
            DESCR_INCLUDE_SOURCE_INFO=true
            shift
            ;;
        --descr-filename)
            shift
            DESCR_FILENAME=$1
            shift
            ;;
        --csharp_opt)
            shift
            CSHARP_OPT=$1
            shift
            ;;
        --scala_opt)
            shift
            SCALA_OPT=$1
            shift
            ;;
        --with-swagger-json-names)
            OPENAPI_JSON=true
            echo "--with-swagger-json-names is deprecated. Please use --with-openapi-json-names instead"
            shift
            ;;
        --with-openapi-json-names)
            OPENAPI_JSON=true
            shift
            ;;
        --generate-unbound-methods)
            GENERATE_UNBOUND_METHODS=true
            shift
            ;;
        --js-out)
            shift
            JS_OUT=$1
            shift
            ;;
        --grpc-web-out)
            shift
            WEB_OUT=$1
            shift
            ;;
        --grpc-out)
            shift
            GRPC_OUT=$1
            shift
            ;;
        --ts_opt)
            shift
            TYPESCRIPT_OPT=$1
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z $FILE && -z $PROTO_DIR ]]; then
    echo "Error: You must specify a proto file or proto directory"
    printUsage
    exit 1
fi

if [[ ! -z $FILE && ! -z $PROTO_DIR ]]; then
    echo "Error: You may specifiy a proto file or directory but not both"
    printUsage
    exit 1
fi

if [ -z $GEN_LANG ]; then
    echo "Error: You must specify a language: ${SUPPORTED_LANGUAGES[@]}"
    printUsage
    exit 1
fi

if [[ ! ${SUPPORTED_LANGUAGES[*]} =~ "$GEN_LANG" ]]; then
    echo "Language $GEN_LANG is not supported. Please specify one of: ${SUPPORTED_LANGUAGES[@]}"
    exit 1
fi

if [[ "$GEN_VALIDATOR" == true && ! ${VALIDATOR_SUPPORTED_LANGUAGES[*]} =~ "$GEN_LANG" ]]; then
    echo "Generating validations are not (yet) supported to $GEN_LANG language. Please specify one of: ${VALIDATOR_SUPPORTED_LANGUAGES[@]}"
    exit 1
fi

if [[ "$GEN_VALIDATOR" == true && "$GO_VALIDATOR" == true ]]; then
    echo "Hi Gopher! Please select just one of the validators (--go-proto-validator or --with-validator)."
    exit 1
fi

if [[ "$GEN_GATEWAY" == true && "$GEN_LANG" != "go" ]]; then
    echo "Generating grpc-gateway is Go specific."
    exit 1
fi

if [[ "$GO_VALIDATOR" == true && "$GEN_LANG" != "go" ]]; then
    echo "Generating proto validator is Go specific."
    exit 1
fi

if [[ "$GEN_RBI" == true && "$GEN_LANG" != "ruby" ]]; then
    echo "Generating RBI declaration files is a Ruby specific option."
    exit 1
fi

if [[ "$GEN_TYPESCRIPT" == true && "$GEN_LANG" != "node" ]]; then
    echo "Generating TypeScript declaration files is Node specific."
    exit 1
fi

if [[ ! -z $GO_SOURCE_RELATIVE && ! -z $GO_MODULE_PREFIX ]]; then
    echo "Error: You may specifiy --go-source-relative or --go-module-prefix but not both"
    printUsage
    exit 1
fi

PLUGIN_LANG=$GEN_LANG
if [ $PLUGIN_LANG == 'objc' ] ; then
    PLUGIN_LANG='objective_c'
fi

if [[ $OUT_DIR == '' ]]; then
    GEN_DIR="gen"
    if [[ $GEN_LANG == "python" ]]; then
        # Python needs underscores to read the directory name.
        OUT_DIR="${GEN_DIR}/pb_$GEN_LANG"
    else
        OUT_DIR="${GEN_DIR}/pb-$GEN_LANG"
    fi
fi

if [[ ! -d $OUT_DIR ]]; then
  # If a .jar is specified, protoc can output to the jar directly. So
  # don't create it as a directory.
  if [[ "$GEN_LANG" == "java" ]] && [[ $OUT_DIR == *.jar ]]; then
    mkdir -p `dirname $OUT_DIR`
  else
    mkdir -p $OUT_DIR
  fi
fi

GEN_STRING=''
case $GEN_LANG in
    "go")
        GEN_STRING="--go_out=${GO_SOURCE_RELATIVE}${GO_MODULE_PREFIX}${GO_PACKAGE_MAP}:$OUT_DIR\
            --go-grpc_out=${GO_SOURCE_RELATIVE}${GO_MODULE_PREFIX}${GO_PACKAGE_MAP}${GO_GRPC_REQUIRE_UNIMPLEMENTED_SERVERS}:$OUT_DIR"
        if [[ ${GO_PLUGIN} == "micro" ]]; then
          GEN_STRING="$GEN_STRING --micro_out=$OUT_DIR"
        fi
        ;;
    "gogo")
        GEN_STRING="--gogofast_out=${GO_SOURCE_RELATIVE}\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
${GO_PACKAGE_MAP}\
plugins=grpc+embedded\
:$OUT_DIR"
        ;;
    "java")
        GEN_STRING="--grpc_out=$OUT_DIR --${GEN_LANG}_out=$OUT_DIR --plugin=protoc-gen-grpc=$(which grpc_java_plugin)"
        ;;
    "scala")
        SCALA_OUT=$OUT_DIR

        if [[ ! -z $SCALA_OPT ]]; then
            SCALA_OUT="$SCALA_OPT:$OUT_DIR"
        fi

        GEN_STRING="--scala_out=$SCALA_OUT --plugin=$(which protoc-gen-scala)"
        ;;
    "node")
        # add plugin
        GEN_STRING="--plugin=protoc-gen-grpc=$(which grpc_tools_node_protoc_plugin)"
        GEN_STRING="$GEN_STRING --js_out=$JS_OUT,binary:$OUT_DIR --grpc_out=$GRPC_OUT:$OUT_DIR"
        ;;
    "web")
        # add plugins
        GEN_STRING=" --plugin=protoc-gen-grpc-web=$(which protoc-gen-grpc-web)"
        GEN_STRING="$GEN_STRING --js_out=$JS_OUT,binary:$OUT_DIR --grpc-web_out=$WEB_OUT,mode=grpcwebtext:$OUT_DIR"
        ;;
    "descriptor_set")
        GEN_STRING="--descriptor_set_out=$OUT_DIR/$DESCR_FILENAME"
        if [[ $DESCR_INCLUDE_IMPORTS ]]; then
            GEN_STRING="$GEN_STRING --include_imports"
        fi
        if [[ $DESCR_INCLUDE_SOURCE_INFO ]]; then
            GEN_STRING="$GEN_STRING --include_source_info"
        fi
        ;;
    "csharp")
        GEN_STRING="--grpc_out=$OUT_DIR --csharp_out=$OUT_DIR --plugin=protoc-gen-grpc=$(which grpc_csharp_plugin)"
        if [[ ! -z $CSHARP_OPT ]]; then
            GEN_STRING="$GEN_STRING --csharp_opt=$CSHARP_OPT"
        fi
        ;;
    "typescript")
        # add plugin
        GEN_STRING="--plugin=$(which protoc-gen-ts_proto)"
        GEN_STRING="$GEN_STRING --ts_proto_out=$OUT_DIR"
        if [[ ! -z $TYPESCRIPT_OPT ]]; then
            GEN_STRING="$GEN_STRING --ts_proto_opt=$TYPESCRIPT_OPT"
        fi
        ;;
    *)
        GEN_STRING="--grpc_out=$OUT_DIR --${GEN_LANG}_out=$OUT_DIR --plugin=protoc-gen-grpc=$(which grpc_${PLUGIN_LANG}_plugin)"
        ;;
esac

if [[ $GO_VALIDATOR == true && $GEN_LANG == "go" ]]; then
    GEN_STRING="$GEN_STRING --govalidators_out=$OUT_DIR"
fi

if [[ $GO_VALIDATOR == true && $GEN_LANG == "gogo" ]]; then
    GEN_STRING="$GEN_STRING --govalidators_out=gogoimport=true:$OUT_DIR"
fi

if [[ $GEN_VALIDATOR == true && $GEN_LANG == "go" ]]; then
    GEN_STRING="$GEN_STRING --validate_out=lang=go${VALIDATOR_SOURCE_RELATIVE}:$OUT_DIR"
fi

if [[ $GEN_VALIDATOR == true && $GEN_LANG == "gogo" ]]; then
    GEN_STRING="$GEN_STRING --validate_out=lang=go${VALIDATOR_SOURCE_RELATIVE}:$OUT_DIR"
fi

if [[ $GEN_VALIDATOR == true && $GEN_LANG == "java" ]]; then
    GEN_STRING="$GEN_STRING --validate_out=lang=java:$OUT_DIR"
fi

if [[ $GEN_DOCS == true ]]; then
    mkdir -p $OUT_DIR/doc
    GEN_STRING="$GEN_STRING --doc_opt=$DOCS_FORMAT --doc_out=$OUT_DIR/doc"
fi

if [[ $GEN_RBI == true ]]; then
    GEN_STRING="$GEN_STRING --rbi_out=$OUT_DIR"
fi

if [[ $GEN_TYPESCRIPT == true ]]; then
    GEN_STRING="$GEN_STRING --plugin=protoc-gen-ts=$(which protoc-gen-ts) --ts_out=$GRPC_OUT:$OUT_DIR"
fi

LINT_STRING=''
if [[ $LINT == true ]]; then
    if [[ $LINT_CHECKS == '' ]]; then
        LINT_STRING="--lint_out=."
    else
        LINT_STRING="--lint_out=$LINT_CHECKS:."
    fi
fi

PROTO_INCLUDE=""
if [[ $NO_GOOGLE_INCLUDES == false ]]; then
  PROTO_INCLUDE="-I /opt/include"
fi

PROTO_INCLUDE="$PROTO_INCLUDE $EXTRA_INCLUDES"

if [ ! -z $PROTO_DIR ]; then
    PROTO_INCLUDE="$PROTO_INCLUDE -I $PROTO_DIR"
    FIND_DEPTH=""
    if [[ $GEN_LANG == "go" ]]; then
        FIND_DEPTH="-maxdepth 1"
    fi
    PROTO_FILES=(`find ${PROTO_DIR} ${FIND_DEPTH} -name "*.proto"`)
else
    PROTO_INCLUDE="-I . $PROTO_INCLUDE"
    PROTO_FILES=($FILE)
fi

# Run protoc
protoc $PROTO_INCLUDE \
    $GEN_STRING \
    $LINT_STRING \
    ${PROTO_FILES[@]}

# Python also needs __init__.py files in each directory to import.
# If __init__.py files are needed at higher level directories (i.e.
# directories above $OUT_DIR), it's the caller's responsibility to
# create them.
if [[ $GEN_LANG == "python" ]]; then
    # Create __init__.py for everything in the OUT_DIR
    # (i.e. gen/pb_python/foo/bar/).
    find $OUT_DIR -type d | xargs -n1 -I '{}' touch '{}/__init__.py'
    # And everything above it (i.e. gen/__init__py")
    d=`dirname $OUT_DIR`
    while [[ "$d" != "." && "$d" != "/" ]]; do
        touch "$d/__init__.py"
        d=`dirname $d`
    done
fi

if [ $GEN_GATEWAY = true ]; then
    GATEWAY_DIR=${OUT_DIR}
    mkdir -p ${GATEWAY_DIR}

    protoc $PROTO_INCLUDE \
        --grpc-gateway_out=${GO_SOURCE_RELATIVE}logtostderr=true:$GATEWAY_DIR ${PROTO_FILES[@]} \
        --grpc-gateway_opt generate_unbound_methods=$GENERATE_UNBOUND_METHODS

    if [[ $OPENAPI_JSON == true ]]; then
        protoc $PROTO_INCLUDE  \
            --openapiv2_out=logtostderr=true,json_names_for_fields=true:$GATEWAY_DIR ${PROTO_FILES[@]} \
            --openapiv2_opt generate_unbound_methods=$GENERATE_UNBOUND_METHODS
    else
        protoc $PROTO_INCLUDE  \
            --openapiv2_out=logtostderr=true,json_names_for_fields=false:$GATEWAY_DIR ${PROTO_FILES[@]} \
            --openapiv2_opt generate_unbound_methods=$GENERATE_UNBOUND_METHODS
    fi
fi
