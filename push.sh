./build.sh

echo "Pushing Docker containers"
docker push registry.namely.tech/namely/protoc
docker push registry.namely.tech/namely/protoc-golang
docker push registry.namely.tech/namely/protoc-ruby
