#!/bin/bash

# Script to test Docker Hub authentication and update GitHub secrets if needed

set -e

echo "🔐 Docker Hub Authentication Troubleshooter"
echo "=========================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo ""
echo "1. Testing current Docker Hub credentials from environment..."

# Check if credentials are in environment
if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "⚠️  DOCKERHUB_USERNAME or DOCKERHUB_TOKEN not set in environment."
    echo -n "Enter Docker Hub username: "
    read -r DOCKERHUB_USERNAME
    echo -n "Enter Docker Hub token: "
    read -s DOCKERHUB_TOKEN
    echo
else
    echo "✅ Found credentials in environment variables."
fi

echo ""
echo "2. Testing Docker Hub login..."
echo "=============================="

# Test login
if echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin; then
    echo "✅ SUCCESS: Docker Hub authentication successful!"
    echo ""
    echo "3. Your credentials are correct."
    echo "   Username: $DOCKERHUB_USERNAME"
    echo "   Token: ****** (hidden for security)"
    
    echo ""
    echo -n "Would you like to update GitHub secrets with these credentials? (y/N): "
    read -r UPDATE_SECRETS
    
    if [[ "$UPDATE_SECRETS" =~ ^[Yy]$ ]]; then
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
        
        # Update secrets
        echo "🔄 Updating GitHub secrets..."
        gh secret set DOCKERHUB_USERNAME --repo=schnicklfritz/aicovermaker --body="$DOCKERHUB_USERNAME"
        gh secret set DOCKERHUB_TOKEN --repo=schnicklfritz/aicovermaker --body="$DOCKERHUB_TOKEN"
        
        echo "✅ GitHub secrets updated!"
        echo ""
        echo "4. Triggering new build..."
        echo "=========================="
        gh workflow run "Build and Push AICoverMaker Docker Image" --repo=schnicklfritz/aicovermaker
        echo "✅ Build triggered! Check progress at:"
        echo "   https://github.com/schnicklfritz/aicovermaker/actions"
    else
        echo "ℹ️  GitHub secrets not updated. Please update them manually:"
        echo "   - Go to: https://github.com/schnicklfritz/aicovermaker/settings/secrets/actions"
        echo "   - Update DOCKERHUB_USERNAME and DOCKERHUB_TOKEN"
    fi
else
    echo "❌ FAILED: Docker Hub authentication failed!"
    echo ""
    echo "3. Troubleshooting steps:"
    echo "   a. Verify your Docker Hub username is correct"
    echo "   b. Check if the token has expired (tokens last 30 days)"
    echo "   c. Ensure token has correct permissions (Read, Write, Delete)"
    echo "   d. Create a new token at: https://hub.docker.com/settings/security"
    echo ""
    echo "4. To create a new Docker Hub token:"
    echo "   - Go to https://hub.docker.com"
    echo "   - Click your profile → Account Settings → Security → Access Tokens"
    echo "   - Click 'Create Access Token'"
    echo "   - Set permissions: Read, Write, Delete"
    echo "   - Copy the token immediately (you won't see it again)"
    echo ""
    echo "5. After getting correct credentials, run this script again."
fi

echo ""
echo "📝 Quick test command for future reference:"
echo "   echo \$DOCKERHUB_TOKEN | docker login --username \$DOCKERHUB_USERNAME --password-stdin"
