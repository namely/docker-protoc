. ./build.sh

echo "Pushing Docker Images"
docker push $REGISTRY/$BASE_IMAGE:$TAG
docker push $REGISTRY/$RUBY_IMAGE:$TAG
docker push $REGISTRY/$GOLANG_IMAGE:$TAG
echo "Done"
