echo "Building proto definitions:"
ls | grep *.proto

echo "Building..."
protoc -I /defs /defs/*.proto --ruby_out=plugins=grpc:.
echo "Done"
