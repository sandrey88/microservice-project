#!/bin/bash

# Скрипт для білду та пушу Django Docker образу до ECR

set -e

# Кольори для виводу
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Build and Push Django Image to ECR ===${NC}"

# Змінні
AWS_REGION="eu-north-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="lesson-7-django-app"
IMAGE_TAG="latest"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo -e "${YELLOW}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${YELLOW}ECR Repository: ${ECR_REPOSITORY}${NC}"
echo -e "${YELLOW}ECR URL: ${ECR_URL}${NC}"

# Перевірка наявності Dockerfile
if [ ! -f "../lesson-4/Dockerfile" ]; then
    echo -e "${RED}Error: Dockerfile not found in lesson-4 directory${NC}"
    exit 1
fi

# Крок 1: Логін до ECR
echo -e "${GREEN}Step 1: Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Крок 2: Білд Docker образу
echo -e "${GREEN}Step 2: Building Docker image...${NC}"
cd ../lesson-4
docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} .

# Крок 3: Тегування образу для ECR
echo -e "${GREEN}Step 3: Tagging image for ECR...${NC}"
docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}

# Крок 4: Пуш образу до ECR
echo -e "${GREEN}Step 4: Pushing image to ECR...${NC}"
docker push ${ECR_URL}:${IMAGE_TAG}

echo -e "${GREEN}=== Successfully pushed image to ECR ===${NC}"
echo -e "${YELLOW}Image URL: ${ECR_URL}:${IMAGE_TAG}${NC}"
