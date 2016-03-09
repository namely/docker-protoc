. ./build.sh

set -e

echo "Pushing Docker Images"
for img in ${IMAGES[@]};
do
  docker push $img
done
echo "Done"
