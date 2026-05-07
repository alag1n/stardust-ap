# Deployment Instructions for Stardust Photo Upload

## 1. Deploy Cloud Function

1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
2. Initialize the SDK: `gcloud init`
3. Set your project: `gcloud config set project YOUR_PROJECT_ID`
4. Deploy the function:
```
cd cloud_function
gcloud functions deploy uploadToGitHub \
  --runtime nodejs18 \
  --trigger-http \
  --allow-unauthenticated \
  --region=us-central1
```

5. Note the function URL (it will be displayed after deployment)

## 2. Update Frontend Configuration

1. Open `stardust/upload.js`
2. Replace `https://your-project-id.cloudfunctions.net/uploadToGitHub` with your actual function URL

## 3. Deploy to GitHub Pages

1. Commit all changes
2. Push to main branch
3. Go to repository Settings > Pages
4. Set source to GitHub Actions or your preferred method

## 4. Setup Custom Domain (Optional)

1. Go to repository Settings > Pages
2. Enter your custom domain
3. Update DNS records with your domain provider

## 5. Test the Application

1. Open your deployed site
2. Try uploading a photo
3. Verify it appears in the stardust-images repository

## Security Notes

- The function has basic validation for file types and size
- Consider implementing additional security measures for production
- Monitor function usage to stay within free tier limits