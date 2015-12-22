echo "Building proto definitions:"
ls | grep *.proto

echo "Building..."
protoc -I /defs /defs/*.proto --ruby_out=./ --grpc_out=./ --plugin=protoc-gen-grpc=`which grpc_ruby_plugin`

echo "Done"
