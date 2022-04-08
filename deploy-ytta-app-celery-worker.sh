sed -e "s|FIRST_SUPERUSER_VALUE|$FIRST_SUPERUSER|g" aws-cloudformation/ytta-app-backend-celery-worker.yaml | tee ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|FIRST_SUPERUSER_PASSWORD_VALUE|$FIRST_SUPERUSER_PASSWORD|g" ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|POSTGRES_SERVER_VALUE|$POSTGRES_SERVER|g" ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|POSTGRES_PASSWORD_VALUE|$POSTGRES_PASSWORD|g" ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|AWS_ACCESS_KEY_ID_VALUE|$AWS_ACCESS_KEY_ID|g" ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|AWS_SECRET_ACCESS_KEY_VALUE|$AWS_SECRET_ACCESS_KEY|g" ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|AWS_DEFAULT_REGION_VALUE|$AWS_DEFAULT_REGION|g" ytta-app-backend-celery-worker-with-secrets.yaml
sed -i -e "s|SQS_URL_VALUE|$SQS_URL|g" ytta-app-backend-celery-worker-with-secrets.yaml
kubectl apply -f ytta-app-backend-celery-worker-with-secrets.yaml
