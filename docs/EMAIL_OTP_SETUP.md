# Email code setup (sign-up and password reset)

For the project owner. Everything here is done by hand in the Supabase and Brevo dashboards; the app does not change any hosted setting. No secrets in this file: you type the SMTP key into Supabase yourself.

## What the app does (build 1.0.0+10 and later)

- **Sign-up with Confirm email on:** the new user gets an email with a 6-digit code and sees a screen to type it in. A right code confirms the account and signs them in. The screen has **Resend code** (a 60-second wait between sends), a way back to sign-in, and clear messages for a wrong or expired code, too many tries and no connection.
- **Sign-up with Confirm email off:** the user is signed in straight away. No code screen.
- **Forgot password:** the user enters an email, then types the 6-digit code from the email plus a new password (same rules as sign-up: at least 8 characters, one capital letter, one number). The app never says whether an email has an account.
- **No link, domain or `AUTH_APP_LINK_HOST` is needed.** That setting, the Android app link and the `assetlinks.json` file are gone.
- A user who left the code screen and later signs in is taken back to the code screen, with Resend ready.

Supabase answers a wrong code and an expired code with the same error, so the app says "wrong or has expired" for both.

**Old builds (1.0.0+9 and earlier) rely on emailed links.** If you switch the templates below to codes while those builds are still installed, their password reset stops working. Install build 10 first.

## Order of work

1. Set up custom SMTP (Brevo), below. Without it, Supabase only emails your own team members and only a few per hour.
2. Replace the two email templates, below.
3. Check the code length and expiry.
4. Turn **Confirm email** on (Authentication, Providers, Email), if you want sign-up to require a code. It is **off** today.
5. Run the test checklist at the end.

## 1. Email templates

In the Supabase dashboard open **Authentication, Emails** (the page is called Email Templates), and edit these two templates. Keep `{{ .Token }}` exactly as written: Supabase fills in the 6-digit code.

### Confirm signup

Subject:

```
Your TricGabay verification code
```

Message body:

```html
<p>Your TricGabay verification code is:</p>
<h2>{{ .Token }}</h2>
<p>Type this code in the TricGabay app to confirm your email.</p>
<p>Never share this code with anyone. TricGabay will never ask you for it.</p>
<p>If you did not sign up for TricGabay, you can ignore this email.</p>
```

### Reset password

Subject:

```
Your TricGabay password reset code
```

Message body:

```html
<p>Your TricGabay password reset code is:</p>
<h2>{{ .Token }}</h2>
<p>Type this code in the TricGabay app, then choose a new password.</p>
<p>Never share this code with anyone. TricGabay will never ask you for it.</p>
<p>If you did not ask to reset your password, you can ignore this email. Your password has not changed.</p>
```

Do not put `{{ .ConfirmationURL }}` in either template. A link would not open the app, and some email scanners open links in advance and use them up.

Other templates (invite, magic link, change email, reauthentication) are not used by the app; leave them alone.

## 2. Code length and expiry

Under **Authentication, Providers, Email**:

- The code must be 6 digits; the app only accepts 6. That is Supabase's default.
- **Email OTP Expiration:** the default is one hour. A shorter time, such as 10 to 15 minutes, is safer. Do not go above one day.

## 3. Brevo SMTP for Supabase

### In Brevo

1. Sign in to Brevo and open **SMTP & API** (the menu is under your account name, top right).
2. Open the **SMTP** tab. Note the **SMTP server**, **port** and **login** shown there.
3. Click **Generate a new SMTP key**, name it (for example `supabase-auth`), and copy the key. **This is an SMTP key, not the API key** that the booking-email Edge Function uses. Brevo shows it once; keep it in your password manager.
4. Open **Senders, domains & dedicated IPs, Senders** and make sure `tricgabay.bustos@gmail.com` is added and **verified** (Brevo sends a confirmation email to it). Brevo will not send from an unverified address.

### In Supabase

Open **Authentication, Emails, SMTP Settings** (the page has moved between Emails and Notifications in different dashboard versions). Turn on **Enable custom SMTP** and fill in:

| Field | Value |
|---|---|
| Sender email | `tricgabay.bustos@gmail.com` |
| Sender name | `TricGabay` |
| Host | `smtp-relay.brevo.com` |
| Port | `587` (alternatives Brevo lists: 465 or 2525) |
| Username | the SMTP login from Brevo's SMTP tab |
| Password | the SMTP key you generated (type or paste it yourself; never save it in this repo) |

Save. Then open **Authentication, Rate Limits** and look at the emails-per-hour limit: with custom SMTP it can be raised, and 60-second spacing per user still applies.

### Things to know about a Gmail sender

- Mail that claims to come from a `@gmail.com` address but is sent through Brevo often fails the sender checks Gmail and others use (SPF/DKIM/DMARC), so it may land in **spam** or be rejected. Test with Gmail and at least one other provider.
- This is fine for a first test. For real use, send from an address on a domain you own, add that domain in Brevo (Senders, domains), and publish the DNS records Brevo shows.
- Brevo's free plan has a daily send limit; check it matches how many sign-ups you expect.

## 4. Test checklist

Use an inbox you control. Do each step on a phone with the build 10 APK.

**Sign-up (Confirm email on)**

- [ ] Sign up as a new tourist. A code email arrives within a minute, from TricGabay, with a 6-digit code and the "never share" line.
- [ ] The app shows "Enter the 6-digit code we emailed you".
- [ ] A wrong code shows "That code is wrong or has expired", and you can try again.
- [ ] Resend shows a 60-second countdown, then sends a new code. The old code stops working.
- [ ] The right code signs you in and opens the tourist home.
- [ ] Sign up again, close the app on the code screen, reopen it and sign in with the password: you are taken to the code screen, and Resend is ready.
- [ ] Sign up as a driver: after the code, the application (documents) finishes and you reach "application pending".
- [ ] With Confirm email **off**, sign-up goes straight into the app with no code screen.

**Password reset**

- [ ] Forgot password with the new account's email: you reach the code and new-password screen, and a reset email arrives.
- [ ] Forgot password with an email that has **no** account: you reach the same screen, no error, no email.
- [ ] A wrong code shows the wrong-or-expired message.
- [ ] A password with no capital letter or no number is refused.
- [ ] The right code and a good password: "Password updated. Sign in again." Sign in with the new password works; the old one does not.
- [ ] Ask for codes several times quickly: the app shows "Too many tries" rather than crashing.

**Email**

- [ ] Both emails read correctly on a phone, and neither contains a link.
- [ ] Check the spam folder at Gmail and at one other provider.

**Afterwards**

- [ ] Delete the test accounts in Authentication, Users.
- [ ] Rotate the SMTP key in Brevo if it was ever shown on a shared screen or pasted anywhere else.
