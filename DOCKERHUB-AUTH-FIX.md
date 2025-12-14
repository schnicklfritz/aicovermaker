# Docker Hub Authentication Fix for AICoverMaker

## Problem
The GitHub Actions build is failing with "unauthorized" error when trying to push to Docker Hub.

## Root Cause
The repository lacks the required GitHub Secrets:
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token

## Solution

### Option 1: Automated Setup (Recommended)

1. **Install GitHub CLI** if not already installed:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install gh
   
   # macOS
   brew install gh
   
   # Windows (Winget)
   winget install GitHub.cli
   ```

2. **Authenticate with GitHub**:
   ```bash
   gh auth login
   ```

3. **Run the setup script**:
   ```bash
   chmod +x setup-secrets.sh
   ./setup-secrets.sh
   ```

4. **Follow the prompts** to enter your Docker Hub credentials.

### Option 2: Manual Setup via GitHub Web Interface

1. Go to your repository: https://github.com/schnicklfritz/aicovermaker
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these secrets:

   **Secret 1: DOCKERHUB_USERNAME**
   - Name: `DOCKERHUB_USERNAME`
   - Value: Your Docker Hub username (e.g., `schnicklbob`)

   **Secret 2: DOCKERHUB_TOKEN**
   - Name: `DOCKERHUB_TOKEN`
   - Value: Your Docker Hub access token (see below for how to create one)

### Creating a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com)
2. Click your profile picture → **Account Settings**
3. Go to **Security** → **Access Tokens**
4. Click **Create Access Token**
5. Give it a name (e.g., "GitHub Actions")
6. Set permissions: **Read, Write, Delete** (or at least Read & Write)
7. Copy the token immediately (you won't see it again)

## Testing Your Credentials

Before adding to GitHub, test locally:

```bash
# Set your credentials as environment variables
export DOCKERHUB_USERNAME="your_username"
export DOCKERHUB_TOKEN="your_token"

# Test login
echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
```

Expected output: `Login Succeeded`

## Triggering a New Build

Once secrets are configured:

### Option A: Push a change
```bash
git commit --allow-empty -m "Trigger build with Docker Hub secrets"
git push
```

### Option B: Manual trigger via GitHub CLI
```bash
gh workflow run "Build and Push AICoverMaker Docker Image" --repo=schnicklfritz/aicovermaker
```

### Option C: Manual trigger via Web UI
1. Go to **Actions** tab in your repository
2. Select **Build and Push AICoverMaker Docker Image**
3. Click **Run workflow**
4. Select branch: `main`
5. Click **Run workflow**

## Verification

1. Check the **Actions** tab for build progress
2. Look for green checkmark indicating success
3. Verify image is available on Docker Hub:
   ```bash
   docker pull schnicklbob/aicovermaker:latest
   ```

## Troubleshooting

### Common Issues

1. **"unauthorized: authentication required"**
   - Verify token has correct permissions (Read & Write)
   - Check username spelling
   - Ensure token hasn't expired

2. **"denied: requested access to the resource is denied"**
   - Verify Docker Hub namespace matches username
   - Check if you have permission to push to that namespace

3. **Build times out**
   - The image is large (CUDA + PyTorch + dependencies)
   - GitHub Actions has a 6-hour timeout, should be sufficient
   - Consider using `cache-from` to speed up builds

4. **Dependency installation fails**
   - Already addressed in updated Dockerfile with better error handling
   - Includes fallback mechanisms for missing dependencies

## Permanent Fix Status

✅ **Dockerfile Issues**: Fixed with robust error handling and dependency management  
✅ **GitHub Actions Workflow**: Updated with better caching and build arguments  
✅ **Authentication Solution**: Provided setup script and documentation  
✅ **Monitoring**: Script includes verification steps  

The build should now succeed once Docker Hub credentials are properly configured.

## Next Steps After Successful Build

1. **Test the image locally**:
   ```bash
   docker run --rm schnicklbob/aicovermaker:latest test-aicovermaker
   ```

2. **Use for audio separation**:
   ```bash
   docker run --gpus all -v $(pwd)/input:/app/data \
     schnicklbob/aicovermaker:latest separator --input /app/data/song.mp3
   ```

3. **Use for voice conversion**:
   ```bash
   docker run --gpus all -v $(pwd)/models:/app/models -p 7860:7860 \
     schnicklbob/aicovermaker:latest applio
   ```

## Support

If issues persist:
1. Check GitHub Actions logs for specific error messages
2. Verify Docker Hub token permissions
3. Ensure GitHub repository has correct secrets configured
4. Review Dockerfile for any platform-specific issues
