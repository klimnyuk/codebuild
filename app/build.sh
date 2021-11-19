aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $id.dkr.ecr.$region.amazonaws.com; \
docker build -t $ecr_repository_url .; \
docker push $ecr_repository_url;