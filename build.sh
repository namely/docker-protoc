echo "Building Docker containers"
docker build -t registry.namely.tech/namely/protoc .
docker build -t registry.namely.tech/namely/protoc-golang ./golang
docker build -t registry.namely.tech/namely/protoc-ruby ./ruby
