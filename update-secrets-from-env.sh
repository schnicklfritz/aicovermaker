#!/bin/bash

# Script to update GitHub secrets from .env file

set -e

echo "🔐 Updating GitHub Secrets from .env file"
echo "=========================================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found in current directory."
    echo "Please create a .env file with:"
    echo "DOCKERHUB_USERNAME=your_username"
    echo "DOCKERHUB_TOKEN=your_token"
    exit 1
fi

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it first: https://cli.github.com/"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "🔑 Please authenticate with GitHub CLI first:"
    echo "   gh auth login"
    exit 1
fi

# Load .env file
echo "📄 Loading .env file..."
source .env

# Check if variables are set
if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "❌ DOCKERHUB_USERNAME or DOCKERHUB_TOKEN not found in .env file."
    echo "Please add them to your .env file:"
    echo "DOCKERHUB_USERNAME=your_username"
    echo "DOCKERHUB_TOKEN=your_token"
    exit 1
fi

echo "✅ Found credentials in .env file."
echo "   Username: $DOCKERHUB_USERNAME"
echo "   Token: ****** (hidden for security)"

echo ""
echo "🔄 Updating GitHub secrets..."

# Update Docker Hub username
gh secret set DOCKERHUB_USERNAME --repo=schnicklfritz/aicovermaker --body="$DOCKERHUB_USERNAME"
echo "✅ Updated DOCKERHUB_USERNAME secret"

# Update Docker Hub token
gh secret set DOCKERHUB_TOKEN --repo=schnicklfritz/aicovermaker --body="$DOCKERHUB_TOKEN"
echo "✅ Updated DOCKERHUB_TOKEN secret"

echo ""
echo "🎉 GitHub secrets updated successfully!"
echo ""
echo "🚀 Triggering new build..."
echo "=========================="

# Trigger new build
gh workflow run "Build and Push AICoverMaker Docker Image" --repo=schnicklfritz/aicovermaker

echo "✅ Build triggered!"
echo ""
echo "📊 Monitor build progress at:"
echo "   https://github.com/schnicklfritz/aicovermaker/actions"
echo ""
echo "💡 Next steps:"
echo "1. Wait for build to complete (10-30 minutes)"
echo "2. Check for green checkmark indicating success"
echo "3. Pull the image: docker pull $DOCKERHUB_USERNAME/aicovermaker:latest"
echo "4. Test: docker run --rm $DOCKERHUB_USERNAME/aicovermaker:latest test-aicovermaker"
