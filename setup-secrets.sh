#!/bin/bash

# Setup script for adding Docker Hub secrets to AICoverMaker GitHub repository
# Run this script to configure secrets for automated Docker builds

set -e

echo "🚀 Setting up Docker Hub secrets for AICoverMaker repository"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "🔑 Please authenticate with GitHub CLI first:"
    echo "   gh auth login"
    exit 1
fi

# Get repository info
REPO_OWNER="schnicklfritz"
REPO_NAME="aicovermaker"

echo "📦 Repository: $REPO_OWNER/$REPO_NAME"

# Check if repository exists
if ! gh repo view "$REPO_OWNER/$REPO_NAME" &> /dev/null; then
    echo "❌ Repository $REPO_OWNER/$REPO_NAME not found or not accessible."
    echo "Please ensure you have access to the repository."
    exit 1
fi

# Add Docker Hub secrets
echo "🔐 Adding Docker Hub secrets..."

# Add DOCKERHUB_USERNAME
echo -n "Enter DOCKERHUB_USERNAME [schnicklbob]: "
read -r DOCKERHUB_USERNAME
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-schnicklbob}

gh secret set DOCKERHUB_USERNAME --repo="$REPO_OWNER/$REPO_NAME" --body="$DOCKERHUB_USERNAME"
echo "✅ Added DOCKERHUB_USERNAME secret"

# Add DOCKERHUB_TOKEN
echo -n "Enter DOCKERHUB_TOKEN: "
read -s DOCKERHUB_TOKEN
echo

if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "⚠️  No token provided. Please enter your Docker Hub token."
    echo -n "Enter DOCKERHUB_TOKEN: "
    read -s DOCKERHUB_TOKEN
    echo
fi

gh secret set DOCKERHUB_TOKEN --repo="$REPO_OWNER/$REPO_NAME" --body="$DOCKERHUB_TOKEN"
echo "✅ Added DOCKERHUB_TOKEN secret"

# Test the secrets by triggering a workflow (optional)
echo ""
echo -n "Would you like to trigger a manual build now? (y/N): "
read -r TRIGGER_BUILD
if [[ "$TRIGGER_BUILD" =~ ^[Yy]$ ]]; then
    echo "🚀 Triggering manual workflow dispatch..."
    gh workflow run "Build and Push AICoverMaker Docker Image" --repo="$REPO_OWNER/$REPO_NAME"
    echo "✅ Workflow triggered! Check progress at:"
    echo "   https://github.com/$REPO_OWNER/$REPO_NAME/actions"
fi

echo ""
echo "🎉 Secrets setup complete!"
echo ""
echo "Next steps:"
echo "1. The GitHub Actions workflow will automatically trigger on next push"
echo "2. Check the Actions tab in your repository:"
echo "   https://github.com/$REPO_OWNER/$REPO_NAME/actions"
echo "3. Once built, pull the image:"
echo "   docker pull schnicklbob/aicovermaker:latest"
echo "4. Run the container:"
echo "   # For audio separation:"
echo "   docker run --gpus all -v \$(pwd)/input:/app/data -v \$(pwd)/models:/app/models \\"
echo "     schnicklbob/aicovermaker:latest separator --input /app/data/song.mp3"
echo ""
echo "   # For Applio voice conversion:"
echo "   docker run --gpus all -v \$(pwd)/input:/app/data -v \$(pwd)/models:/app/models \\"
echo "     -p 7860:7860 schnicklbob/aicovermaker:latest applio"
echo ""
echo "Troubleshooting:"
echo "- If build fails, check the workflow logs for details"
echo "- Ensure Docker Hub token has proper permissions (read/write)"
echo "- Verify repository name matches in Dockerfile tags"
