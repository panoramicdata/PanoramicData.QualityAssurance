# Authentication Setup

This directory stores saved authentication state (cookies, localStorage, sessionStorage) for Magic Suite tests.

## Files
- `user.json` - Saved authentication state for your Magic Suite login

## Security
⚠️ **IMPORTANT**: This file contains your login session cookies!
- Never commit this file to git (it's in .gitignore)
- Keep this file secure on your local machine
- Regenerate if you suspect it's been compromised

## How It Works
The `auth.setup.ts` script logs you in once and saves your session here.
All tests then reuse this authentication state instead of logging in each time.
