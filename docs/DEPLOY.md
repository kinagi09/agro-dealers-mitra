# Deploying Agro Dealers Mitra

Steps that need your own account access (I can't do these) are marked **[YOU]**.
Everything else is already prepared in the repo.

## Backend + Database + Reminder Cron (Render)

1. **[YOU]** Sign up at [render.com](https://render.com), connect it to your
   GitHub account, and grant access to the `agro-dealers-mitra` repo.
2. **[YOU]** In Render, choose **New → Blueprint**, point it at this repo -
   it will read `backend/render.yaml` and provision the web service, the
   cron job, and the Postgres database together.
3. **[YOU]** Upload the Firebase service-account key as a **Secret File** on
   *both* the web service and the cron job (Render dashboard → service →
   Environment → Secret Files): path `/etc/secrets/firebase-service-account.json`,
   contents = the JSON key file you already generated in Firebase.
4. **[YOU]** In your domain registrar, point `api.agrodealersmitra.in` at the
   Render web service (Render gives you the exact CNAME/A record once the
   service is created).
5. Once live, tell me the working `https://api.agrodealersmitra.in` URL so I
   can update the Flutter app's `API_BASE_URL` (currently your LAN IP) and
   the website's API calls to point at it instead of localhost/LAN.

`render.yaml` is sized on Render's **Starter** plan for both the web service
and the database, appropriate for the ~1000-user starting scale - upgradeable
later from the Render dashboard without any code changes if usage grows.

## Website (Vercel)

1. **[YOU]** Sign up at [vercel.com](https://vercel.com), connect GitHub,
   import the `agro-dealers-mitra` repo, set the project root to `website/`.
2. **[YOU]** Point `agrodealersmitra.in` (root domain) at Vercel via the DNS
   records it provides.
3. Vercel auto-deploys on every push to `master` once connected - no
   ongoing manual steps after this.

## Play Store Publishing

Not started yet - see the "Play Store publishing prep" stage. Blocking items:
- Real release keystore (app currently signs release builds with the
  **debug** key - must be replaced before the first Play Store upload).
- **[YOU]** Google Play Console account ($25 one-time).
- Privacy Policy + Terms of Service pages (required in the store listing) -
  planned to live on the website once it's deployed.

## Payment Subscriptions (Razorpay)

Not started yet - waiting on **[YOU]** to create a Razorpay account and
share Test Mode API keys (see chat for the exact steps). Nothing payment-related
ships until this is built and tested end-to-end against those test keys.
