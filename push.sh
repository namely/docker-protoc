. ./build.sh

set -e

echo "Pushing Docker Images"
for img in ${IMAGES[@]};
do
  echo
  echo "Pushing $img to docker hub..."
  docker push $img
done
echo "Done"
