echo "Building proto definitions:"
ls | grep *.proto

echo "Building..."
protoc -I /defs /defs/*.proto --go_out=plugins=grpc:.
echo "Done"
