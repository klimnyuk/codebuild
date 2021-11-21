aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $Account_ID.dkr.ecr.$AWS_REGION.amazonaws.com; \
docker build -t $image_url:$tag .; \
docker push $image_url:$tag;