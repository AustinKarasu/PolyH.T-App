# PolyH.T APK Release Flow

## GitHub Variables

Set these repository variables in GitHub:

- `API_BASE_URL`: production backend URL, for example `https://api.yourdomain.com/api`
- `WEBSITE_BASE_URL`: public website URL where APKs and update JSON are hosted

## GitHub Secrets

For signed production APKs, create one Android keystore and add:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Create the base64 value locally:

```bash
base64 -w 0 release.jks
```

## Build a New Release

1. Open GitHub Actions.
2. Run `Release APKs`.
3. Enter a new `versionName` and a higher `buildNumber`.
4. The workflow builds Admin and Student APKs, creates a GitHub Release, and publishes:
   - `/releases/polyht_admin_latest.json`
   - `/releases/polyht_student_latest.json`
   - both APK files

## App Update Button

Both apps have an update button in the main app bar. Android does not allow normal apps to silently self-install APKs, so the button opens the newest APK download link from the update manifest.
