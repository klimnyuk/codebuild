aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $id.dkr.ecr.$region.amazonaws.com; \
docker build -t $image_url .; \
docker push $image_url;