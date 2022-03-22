sed -e "s|FIRST_SUPERUSER_VALUE|$FIRST_SUPERUSER|g" aws-cloudformation/ytta-app-backend-deployment.yaml | tee ytta-app-backend-deployment-with-secrets.yaml
sed -i -e "s|FIRST_SUPERUSER_PASSWORD_VALUE|$FIRST_SUPERUSER_PASSWORD|g" ytta-app-backend-deployment-with-secrets.yaml
sed -i -e "s|POSTGRES_SERVER_VALUE|$POSTGRES_SERVER|g" ytta-app-backend-deployment-with-secrets.yaml
sed -i -e "s|POSTGRES_PASSWORD_VALUE|$POSTGRES_PASSWORD|g" ytta-app-backend-deployment-with-secrets.yaml
kubectl apply -f ytta-app-backend-deployment-with-secrets.yaml
